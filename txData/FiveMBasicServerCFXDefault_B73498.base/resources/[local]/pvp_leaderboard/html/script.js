// ==========================================
// PVP LEADERBOARD - JAVASCRIPT
// ==========================================

const avatarColors = ['avatar-red', 'avatar-gold', 'avatar-blue', 'avatar-green', 'avatar-purple', 'avatar-cyan', 'avatar-orange'];

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.type === 'open') {
        document.getElementById('leaderboard').classList.remove('hidden');
    }

    if (data.type === 'update') {
        document.getElementById('leaderboard').classList.remove('hidden');
        renderLeaderboard(data.data);
    }

    if (data.type === 'close') {
        document.getElementById('leaderboard').classList.add('hidden');
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});

function closeMenu() {
    document.getElementById('leaderboard').classList.add('hidden');
    fetch('https://pvp_leaderboard/close', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

function renderLeaderboard(data) {
    // Stats globales
    document.getElementById('stat-online').textContent = formatNumber(data.onlineCount || 0);
    document.getElementById('stat-total').textContent = formatNumber(data.totalPlayers || 0);
    document.getElementById('stat-kills').textContent = formatNumber(data.totalKills || 0);
    document.getElementById('stat-topkd').textContent = data.topKD || '0';

    // Mes stats
    const myStatsDiv = document.getElementById('my-stats');
    if (data.myStats) {
        const myDeaths = data.myStats.deaths || 0;
        const myKD = myDeaths > 0 ? ((data.myStats.kills || 0) / myDeaths).toFixed(1) : (data.myStats.kills || 0).toFixed(1);
        myStatsDiv.innerHTML = `
            <div>
                <div class="my-stats-label">MES STATS</div>
                <div class="my-stats-name">${escapeHtml(data.myStats.name || 'Inconnu')}</div>
            </div>
            <div class="my-stats-data">
                <div class="my-stat-item">
                    <div class="my-stat-val">${formatNumber(data.myStats.kills || 0)}</div>
                    <div class="my-stat-lbl">KILLS</div>
                </div>
                <div class="my-stat-item">
                    <div class="my-stat-val">${formatNumber(data.myStats.deaths || 0)}</div>
                    <div class="my-stat-lbl">MORTS</div>
                </div>
                <div class="my-stat-item">
                    <div class="my-stat-val">${myKD}</div>
                    <div class="my-stat-lbl">K/D</div>
                </div>
            </div>
        `;
    } else {
        myStatsDiv.innerHTML = '';
    }

    // Liste des joueurs
    const list = document.getElementById('lb-list');
    const players = data.players || [];

    if (players.length === 0) {
        list.innerHTML = '<div class="lb-empty">Aucune donnée disponible</div>';
        return;
    }

    let html = '';
    players.forEach(function(player, index) {
        const rank = index + 1;
        const deaths = player.deaths || 0;
        const kills = player.kills || 0;
        const kd = deaths > 0 ? (kills / deaths).toFixed(1) : kills.toFixed(1);

        // KD color
        let kdClass = 'kd-low';
        if (parseFloat(kd) >= 3) kdClass = 'kd-high';
        else if (parseFloat(kd) >= 1) kdClass = 'kd-mid';

        // KD bar (max at 10)
        const kdPercent = Math.min(100, (parseFloat(kd) / 10) * 100);
        const kdBarColor = parseFloat(kd) >= 3 ? '#d4a840' : parseFloat(kd) >= 1 ? '#aaa' : '#555';

        // Rank badge
        let rankBadgeClass = 'rank-default-badge';
        let rankRowClass = '';
        if (rank === 1) { rankBadgeClass = 'rank-1-badge'; rankRowClass = 'rank-1'; }
        else if (rank === 2) { rankBadgeClass = 'rank-2-badge'; rankRowClass = 'rank-2'; }
        else if (rank === 3) { rankBadgeClass = 'rank-3-badge'; rankRowClass = 'rank-3'; }

        // Avatar
        const initial = (player.name || '?').charAt(0).toUpperCase();
        const colorIndex = (player.name || '').charCodeAt(0) % avatarColors.length;
        const avatarClass = avatarColors[colorIndex];

        html += `
            <div class="lb-row ${rankRowClass}" data-name="${(player.name || '').toLowerCase()}">
                <span class="lb-col-rank">
                    <span class="rank-badge ${rankBadgeClass}">${rank}</span>
                </span>
                <span class="lb-col-name">
                    <span class="player-avatar ${avatarClass}">${initial}</span>
                    <span class="player-info">
                        <span class="lb-player-name">${escapeHtml(player.name || 'Inconnu')}</span>
                        <span class="lb-player-sub">${formatNumber(deaths)} morts</span>
                    </span>
                </span>
                <span class="lb-col-kills">
                    <span class="kills-value">${formatNumber(kills)}</span>
                    <span class="kills-label">kills</span>
                </span>
                <span class="lb-col-kd">
                    <span class="kd-value ${kdClass}">${kd}</span>
                    <div class="kd-bar">
                        <div class="kd-bar-fill" style="width: ${kdPercent}%; background: ${kdBarColor};"></div>
                    </div>
                </span>
            </div>
        `;
    });

    list.innerHTML = html;
}

function filterLeaderboard() {
    const search = document.getElementById('lb-search-input').value.toLowerCase();
    const rows = document.querySelectorAll('.lb-row');
    rows.forEach(function(row) {
        const name = row.getAttribute('data-name');
        row.style.display = name.includes(search) ? 'flex' : 'none';
    });
}

function formatNumber(num) {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
