document.addEventListener('DOMContentLoaded', function() {
    const container = document.getElementById('container');
    const closeBtn = document.getElementById('close-btn');
    const zonesList = document.getElementById('zones-list');

    // Écoute les messages de Lua (NUI)
    window.addEventListener('message', function(event) {
        const data = event.data;

        if (data.type === 'open') {
            document.body.style.backgroundColor = 'rgba(0, 0, 0, 0.4)'; // Affiche le fond sombre
            container.classList.remove('hidden');
            renderZones(data.safezones);
        } else if (data.type === 'close') {
            closeMenu();
        }
    });

    // Fermer avec le bouton
    closeBtn.addEventListener('click', closeMenu);

    // Fermer avec Echap
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeMenu();
        }
    });

    function closeMenu() {
        container.classList.add('hidden');
        document.body.style.backgroundColor = 'transparent';
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
    }

    function renderZones(zones) {
        zonesList.innerHTML = '';

        if (!zones || zones.length === 0) {
            zonesList.innerHTML = '<div style="color:#aaa; text-align:center; padding:20px; font-weight:600;">Aucune safezone disponible aux alentours.</div>';
            return;
        }

        zones.forEach(zone => {
            const item = document.createElement('div');
            item.className = 'zone-item';
            item.innerHTML = `
                <div class="zone-info">
                    <h2><i class="fa-solid fa-shield-halved"></i> ${zone.name}</h2>
                    <p>
                        <span><i class="fa-solid fa-ruler"></i> Rayon : ${zone.radius || 50}m</span>
                    </p>
                </div>
            `;

            // Double clic pour se TP
            item.addEventListener('dblclick', function() {
                container.classList.add('hidden');
                document.body.style.backgroundColor = 'transparent';
                
                // Envoie l'action au serveur/client
                fetch(`https://${GetParentResourceName()}/teleport`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({
                        x: zone.x,
                        y: zone.y,
                        z: zone.z,
                        heading: zone.heading
                    })
                });
            });

            zonesList.appendChild(item);
        });
    }
});
