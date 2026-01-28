// buildbuild Dashboard Application

const CONFIG = {
    // Repository configuration - update these for your setup
    cacheOwner: 'NerdGGuy',
    cacheRepo: 'PUSH',
    statusOwner: 'NerdGGuy',
    statusRepo: 'POST',

    // Variants to display
    variants: ['release', 'debug', 'asan', 'ubsan', 'tsan', 'msan', 'coverage', 'fuzz'],

    // Data paths
    currentPath: 'data/current.json',
    historyPath: 'data/history.json'
};

// Utility functions
function formatDate(isoString) {
    if (!isoString) return 'Unknown';
    const date = new Date(isoString);
    return date.toLocaleString();
}

function formatRelativeTime(isoString) {
    if (!isoString) return 'Unknown';
    const date = new Date(isoString);
    const now = new Date();
    const diff = now - date;

    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return `${days}d ago`;
}

function getCacheLogUrl(logHash) {
    return `https://raw.githubusercontent.com/${CONFIG.cacheOwner}/${CONFIG.cacheRepo}/main/logs/${logHash}.log`;
}

function getBadgeUrl(variant) {
    return `badges/${variant}.svg`;
}

// Data fetching
async function fetchCurrentStatus() {
    try {
        const response = await fetch(CONFIG.currentPath);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return await response.json();
    } catch (error) {
        console.error('Failed to fetch current status:', error);
        return null;
    }
}

async function fetchHistory() {
    try {
        const response = await fetch(CONFIG.historyPath);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return await response.json();
    } catch (error) {
        console.error('Failed to fetch history:', error);
        return null;
    }
}

// Rendering functions
function renderVariantCard(name, data) {
    const status = data?.status || 'unknown';
    const version = data?.version || 'N/A';
    const timestamp = data?.timestamp;
    const logHash = data?.log_hash;
    const storePath = data?.store_path || '';
    const rev = data?.rev || '';

    const card = document.createElement('div');
    card.className = 'variant-card';

    card.innerHTML = `
        <h3>
            <span class="status-indicator ${status}"></span>
            ${name}
        </h3>
        <div class="details">
            <p><strong>Status:</strong> ${status}</p>
            <p><strong>Version:</strong> ${version}</p>
            <p><strong>Updated:</strong> ${formatRelativeTime(timestamp)}</p>
            ${rev ? `<p><strong>Commit:</strong> ${rev.substring(0, 7)}</p>` : ''}
        </div>
        <div class="actions">
            ${logHash ? `<a href="${getCacheLogUrl(logHash)}" target="_blank">View Log</a>` : ''}
            ${storePath ? `<a href="#" onclick="copyToClipboard('${storePath}'); return false;">Copy Store Path</a>` : ''}
        </div>
    `;

    return card;
}

function renderCurrentStatus(data) {
    const grid = document.getElementById('variant-grid');
    const lastUpdated = document.getElementById('last-updated');

    if (!data) {
        grid.innerHTML = '<div class="error">Failed to load status data</div>';
        return;
    }

    lastUpdated.textContent = formatDate(data.updated);
    grid.innerHTML = '';

    for (const variant of CONFIG.variants) {
        const variantData = data.variants?.[variant];
        const card = renderVariantCard(variant, variantData);
        grid.appendChild(card);
    }
}

function renderHistoryChart(data) {
    const chart = document.getElementById('history-chart');

    if (!data?.builds || data.builds.length === 0) {
        chart.innerHTML = '<div class="loading">No history available</div>';
        return;
    }

    chart.innerHTML = '';

    // Show last 50 builds
    const builds = data.builds.slice(-50);

    for (const build of builds) {
        const bar = document.createElement('div');
        bar.className = 'history-bar';
        bar.title = formatDate(build.timestamp);

        for (const variant of CONFIG.variants) {
            const status = build.variants?.[variant]?.status || 'unknown';
            const cell = document.createElement('div');
            cell.className = `history-cell ${status}`;
            bar.appendChild(cell);
        }

        chart.appendChild(bar);
    }
}

function renderHistoryTable(data) {
    const tbody = document.getElementById('history-body');

    if (!data?.builds || data.builds.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="loading">No history available</td></tr>';
        return;
    }

    tbody.innerHTML = '';

    // Show last 20 builds in table
    const builds = data.builds.slice(-20).reverse();

    for (const build of builds) {
        const row = document.createElement('tr');

        // Timestamp cell
        const timeCell = document.createElement('td');
        timeCell.textContent = formatRelativeTime(build.timestamp);
        timeCell.title = formatDate(build.timestamp);
        row.appendChild(timeCell);

        // Variant cells (only showing subset for table width)
        const tableVariants = ['release', 'debug', 'asan', 'ubsan', 'tsan', 'coverage'];
        for (const variant of tableVariants) {
            const cell = document.createElement('td');
            const status = build.variants?.[variant]?.status || 'unknown';
            cell.textContent = status === 'pass' ? '\u2713' : status === 'fail' ? '\u2717' : '?';
            cell.className = status;
            row.appendChild(cell);
        }

        tbody.appendChild(row);
    }
}

function renderBadges() {
    const list = document.getElementById('badge-list');
    list.innerHTML = '';

    const baseUrl = `https://${CONFIG.statusOwner}.github.io/${CONFIG.statusRepo}`;

    for (const variant of CONFIG.variants) {
        const item = document.createElement('div');
        item.className = 'badge-item';

        const badgeUrl = `${baseUrl}/${getBadgeUrl(variant)}`;
        const markdown = `![${variant}](${badgeUrl})`;

        item.innerHTML = `
            <img src="${getBadgeUrl(variant)}" alt="${variant} badge" />
            <code>${markdown}</code>
        `;

        list.appendChild(item);
    }
}

// Clipboard utility
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        // Could show a toast notification here
        console.log('Copied to clipboard:', text);
    }).catch(err => {
        console.error('Failed to copy:', err);
    });
}

// Initialize dashboard
async function init() {
    // Show loading state
    document.getElementById('variant-grid').innerHTML = '<div class="loading">Loading...</div>';

    // Fetch data in parallel
    const [currentData, historyData] = await Promise.all([
        fetchCurrentStatus(),
        fetchHistory()
    ]);

    // Render components
    renderCurrentStatus(currentData);
    renderHistoryChart(historyData);
    renderHistoryTable(historyData);
    renderBadges();

    // Auto-refresh every 5 minutes
    setInterval(async () => {
        const newData = await fetchCurrentStatus();
        if (newData) {
            renderCurrentStatus(newData);
        }
    }, 300000);
}

// Start when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
