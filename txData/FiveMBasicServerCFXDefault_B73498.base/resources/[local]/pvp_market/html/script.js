'use strict';

const $ = id => document.getElementById(id);

const app = $('app');
const buyGrid = $('buyGrid');
const sellGrid = $('sellGrid');
const myPoints = $('myPoints');
const notifs = $('notifs');

let catalogData = [];
let inventoryData = [];

window.addEventListener('message', ({ data }) => {
    switch (data.action) {
        case 'openMarket': openMarket(data); break;
        case 'setPoints': setPoints(data.points); break;
        case 'updateInventory': updateInventory(data.inventory); break;
        case 'notify': showNotif(data.text, data.type); break;
    }
});

const post = (ep, body = {}) => fetch(`https://${GetParentResourceName()}/${ep}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
});

function openMarket(data) {
    catalogData = data.catalog || [];
    inventoryData = data.inventory || [];
    renderBuy();
    renderSell();
    app.classList.remove('hidden');
}

function closeMarket() {
    app.classList.add('hidden');
    post('close');
}

function setPoints(pts) {
    myPoints.textContent = pts;
}

function updateInventory(inv) {
    inventoryData = inv || [];
    renderSell();
}

function renderBuy() {
    if (!catalogData.length) {
        buyGrid.innerHTML = '<div class="empty-msg">Aucun article à vendre</div>';
        return;
    }
    let html = '';
    catalogData.forEach(w => {
        html += `
            <div class="weapon-card">
                <img src="nui://images/Weapons/${w.hash}.png" class="w-icon" style="object-fit: contain;" alt="${w.name}" onerror="this.onerror=null; this.style.display='none';">
                <div class="w-name">${w.name}</div>
                <div class="w-price">${w.price} ★</div>
                <button class="btn btn-buy" onclick="buyWeapon('${w.hash}')">ACHETER</button>
            </div>
        `;
    });
    buyGrid.innerHTML = html;
}

function renderSell() {
    if (!inventoryData.length) {
        sellGrid.innerHTML = '<div class="empty-msg">Votre inventaire est vide</div>';
        return;
    }
    let html = '';
    inventoryData.forEach(w => {
        html += `
            <div class="weapon-card">
                <img src="nui://images/Weapons/${w.hash}.png" class="w-icon" style="object-fit: contain;" alt="${w.name}" onerror="this.onerror=null; this.style.display='none';">
                <div class="w-name">${w.name}</div>
                <div class="w-price sell">+${w.value} ★</div>
                <button class="btn btn-sell" onclick="sellWeapon('${w.uuid}')">VENDRE</button>
            </div>
        `;
    });
    sellGrid.innerHTML = html;
}

window.buyWeapon = function(hash) {
    post('buyWeapon', { hash });
};

window.sellWeapon = function(uuid) {
    post('sellWeapon', { uuid });
};

// Tabs
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        btn.classList.add('active');
        $('tab-' + btn.dataset.tab).classList.add('active');
    });
});

$('closeBtn').addEventListener('click', closeMarket);

document.addEventListener('keydown', e => {
    if ((e.key === 'Escape' || e.key === 'Backspace' || e.key === 'e') && !app.classList.contains('hidden')) {
        closeMarket();
    }
});

// Notifications
let notifQ = [];
function showNotif(msg, type = 'info') {
    if (notifQ.length >= 4) { notifQ[0].remove(); notifQ.shift(); }
    const el = document.createElement('div');
    el.className = `notif ${type}`;
    el.textContent = msg;
    notifs.appendChild(el);
    notifQ.push(el);
    setTimeout(() => { el.remove(); notifQ = notifQ.filter(n => n !== el); }, 3500);
}
