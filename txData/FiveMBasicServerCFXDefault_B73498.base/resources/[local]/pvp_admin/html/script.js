// ==========================================
// MENU ADMIN - LOGIQUE JAVASCRIPT
// ==========================================

let allPlayers = [];

// Écoute les messages envoyés depuis le script Lua (client.lua)
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.type === 'open') {
        // Ouvre le menu et affiche les joueurs
        document.getElementById('player-menu').classList.remove('hidden');
        allPlayers = data.players || [];
        renderPlayers(allPlayers);
    }

    if (data.type === 'close') {
        document.getElementById('player-menu').classList.add('hidden');
    }
});

// Ferme le menu avec Echap
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});

// Fermer le menu
function closeMenu() {
    document.getElementById('player-menu').classList.add('hidden');
    // Prévient le script Lua qu'on ferme le menu
    fetch('https://pvp_admin/close', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

// Affiche la liste des joueurs dans le menu
function renderPlayers(players) {
    const list = document.getElementById('player-list');
    const count = document.getElementById('player-count');

    count.textContent = players.length + ' joueur' + (players.length > 1 ? 's' : '');

    if (players.length === 0) {
        list.innerHTML = '<div class="no-players">Aucun joueur connecté</div>';
        return;
    }

    let html = '';
    players.forEach(function(player) {
        // Calcul du pourcentage de vie
        const healthPercent = Math.max(0, Math.min(100, ((player.health - 100) / (player.maxHealth - 100)) * 100));
        const healthColor = healthPercent > 60 ? '#44ff44' : healthPercent > 30 ? '#ffaa00' : '#ff4444';

        // Couleur du ping
        let pingClass = 'ping-good';
        if (player.ping > 100) pingClass = 'ping-medium';
        if (player.ping > 200) pingClass = 'ping-bad';

        html += `
            <div class="player-row" data-name="${player.name.toLowerCase()}">
                <span class="col-id">
                    <span class="id-badge">${player.id}</span>
                </span>
                <span class="col-name">
                    <span class="player-name">${escapeHtml(player.name)}</span>
                </span>
                <span class="col-health">
                    <div class="health-bar-container">
                        <div class="health-bar" style="width: ${healthPercent}%; background: ${healthColor};"></div>
                    </div>
                    <span class="health-text">${Math.round(healthPercent)}%</span>
                </span>
                <span class="col-ping">
                    <span class="ping-text ${pingClass}">${player.ping}ms</span>
                </span>
                <span class="col-actions">
                    <button class="action-btn btn-goto" onclick="doAction('goto ${player.id}')">TP</button>
                    <button class="action-btn btn-bring" onclick="doAction('bring ${player.id}')">BRING</button>
                    <button class="action-btn btn-revive" onclick="doAction('revive ${player.id}')">REVIVE</button>
                    <button class="action-btn btn-heal" onclick="doAction('heal ${player.id}')">HEAL</button>
                </span>
            </div>
        `;
    });

    list.innerHTML = html;
}

// Exécute une action admin (envoie la commande au client Lua)
function doAction(command) {
    fetch('https://pvp_admin/action', {
        method: 'POST',
        body: JSON.stringify({ command: command })
    });
}

// Filtre les joueurs par nom
function filterPlayers() {
    const search = document.getElementById('search-input').value.toLowerCase();
    const rows = document.querySelectorAll('.player-row');

    rows.forEach(function(row) {
        const name = row.getAttribute('data-name');
        if (name.includes(search)) {
            row.style.display = 'flex';
        } else {
            row.style.display = 'none';
        }
    });
}

// Protection contre le XSS (empêche les joueurs de mettre du HTML dans leur nom)
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
