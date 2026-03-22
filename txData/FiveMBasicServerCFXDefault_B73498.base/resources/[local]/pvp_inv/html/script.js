'use strict';

const $ = id => document.getElementById(id);

const appEl        = $('app');
const weaponsGrid  = $('weaponsGrid');
const tradeGrid    = $('tradeGrid');
const playersList  = $('playersList');
const actionBox    = $('actionBox');
const tradeModal   = $('tradeModal');
const notifsEl     = $('notifs');
const shortcutGrid = $('shortcutGrid');
const shortcutBar  = $('shortcutBar');
const bagWeight    = $('bagWeight');
const actionWname  = $('actionWname');
const actionPname  = $('actionPname');
const tmFrom       = $('tmFrom');
const tmWeapon     = $('tmWeapon');

let weaponsData    = [];
let playersData    = [];
// shortcuts[0..4] = { hash, name, cat } ou null — miroir du Lua
let shortcuts      = [null, null, null, null, null];
let selectedWeapon = null;
let selectedPlayer = null;
let currentTradeId = null;
let notifQ         = [];
let dragItem       = null;
let dragOriginEl   = null;

function getImg(name) { return `https://cfx-nui-images/Weapons/${name.replace(/ /g, '%20')}.png`; }

function imgHTML(name) {
    const src = getImg(name);
    return `<img src="${src}" class="item-img" alt="${name}" onerror="this.onerror=null; this.style.display='none';">`;
}

// ══ NUI messages ══
window.addEventListener('message', ({ data }) => {
    switch (data.action) {
        case 'openInventory': openInventory(data);                              break;
        case 'setPoints':     if(document.getElementById('myPoints')) document.getElementById('myPoints').textContent = data.points; break;
        case 'notification':  showNotif(data.msg, data.ntype || 'info');        break;
        case 'tradeRequest':  showTradeModal(data);                             break;
        case 'tradeAccepted':
        case 'tradeDeclined': hideTradeModal();                                 break;
    }
});

const post = (ep, body = {}) => fetch(`https://${GetParentResourceName()}/${ep}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
});

// ══ OPEN / CLOSE ══
function openInventory(data) {
    weaponsData    = data.weapons       || [];
    playersData    = data.nearbyPlayers || [];
    selectedWeapon = null;
    selectedPlayer = null;

    // Restaure les shortcuts depuis Lua
    shortcuts = [null, null, null, null, null];
    if (data.shortcuts) {
        for (let i = 1; i <= 5; i++) {
            if (data.shortcuts[i]) shortcuts[i - 1] = data.shortcuts[i];
        }
    }

    renderWeapons();
    renderTradeGrid();
    renderPlayers();
    renderShortcutGrid();
    actionBox.classList.add('hidden');
    bagWeight.textContent = weaponsData.length + ' arme(s)';
    switchTab('inventory');
    appEl.classList.remove('hidden');
}

function closeInventory() {
    cancelDrag();
    appEl.classList.add('hidden');
    selectedWeapon = null;
    selectedPlayer = null;
    post('closeInventory');
}

// Mapping par position physique (e.code) — fonctionne AZERTY + QWERTY
const KEY_SLOT = {
    'Digit1': 1, 'Numpad1': 1,
    'Digit2': 2, 'Numpad2': 2,
    'Digit3': 3, 'Numpad3': 3,
    'Digit4': 4, 'Numpad4': 4,
    'Digit5': 5, 'Numpad5': 5,
};

document.addEventListener('keydown', e => {
    const invOpen = !appEl.classList.contains('hidden');

    if ((e.key === 'Tab' || e.key === 'Escape') && invOpen) {
        e.preventDefault();
        closeInventory();
        return;
    }

    const slot = KEY_SLOT[e.code];
    if (!slot) return;

    if (invOpen) {
        // Inventaire ouvert → binder l'arme survolée
        const hovered = weaponsGrid.querySelector('.item-card:hover');
        const card    = hovered || null;
        if (card) {
            const i = parseInt(card.dataset.index);
            const w = weaponsData[i];
            if (w) {
                shortcuts[slot - 1] = { uuid: w.uuid, hash: w.hash, name: w.name, cat: w.cat };
                post('bindShortcut', { slot, uuid: w.uuid });
                renderShortcutGrid();
                const slotEl = shortcutGrid.querySelector(`[data-slot="${slot}"]`);
                if (slotEl) { slotEl.classList.add('flash'); setTimeout(() => slotEl.classList.remove('flash'), 500); }
            }
        }
    } else {
        // Inventaire fermé → toggle équiper/déséquiper via Lua
        post('shortcutKey', { slot });
    }
});

$('closeBtn').addEventListener('click', closeInventory);
$('closeBtn2').addEventListener('click', closeInventory);

// ══ TABS ══
function switchTab(tab) {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    $('tab-' + tab).classList.add('active');
    document.querySelector(`[data-tab="${tab}"]`).classList.add('active');
}
document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => switchTab(item.dataset.tab));
});

// ══ RENDER WEAPONS ══
function renderWeapons() {
    if (!weaponsData.length) {
        weaponsGrid.innerHTML = '<div class="empty-msg">Aucune arme dans l\'inventaire</div>';
        return;
    }
    const frag = document.createDocumentFragment();
    weaponsData.forEach((w, i) => {
        const d = document.createElement('div');
        d.className = 'item-card';
        d.dataset.index = i;
        d.innerHTML = `
            ${imgHTML(w.name)}
            <div class="item-footer">
                <span class="item-fname" style="text-align: center; width: 100%;">${w.name}</span>
            </div>
            <div class="item-actions">
                <button class="btn-sc" data-action="equip">ÉQUIPER</button>
                <button class="btn-sc drop" data-action="drop">JETER</button>
            </div>`;
        d.addEventListener('mousedown', e => { if (e.button === 0) startDrag(e, w, d); });
        frag.appendChild(d);
    });
    weaponsGrid.innerHTML = '';
    weaponsGrid.appendChild(frag);
}

function renderTradeGrid() {
    if (!weaponsData.length) {
        tradeGrid.innerHTML = '<div class="empty-msg">Aucune arme</div>';
        return;
    }
    const frag = document.createDocumentFragment();
    weaponsData.forEach((w, i) => {
        const d = document.createElement('div');
        d.className = 'item-card';
        d.dataset.index = i;
        d.innerHTML = `${imgHTML(w.name)}<div class="item-footer"><span class="item-fname" style="text-align: center; width: 100%;">${w.name}</span></div>`;
        frag.appendChild(d);
    });
    tradeGrid.innerHTML = '';
    tradeGrid.appendChild(frag);
}

// ══ RENDER SHORTCUTS ══
function renderShortcutGrid() {
    shortcutGrid.querySelectorAll('.sc-inv-slot').forEach((slot, i) => {
        const sc      = shortcuts[i];
        const content = slot.querySelector('.sc-inv-content');
        slot.classList.toggle('filled', !!sc);
        if (sc) {
            const src = getImg(sc.name);
            content.innerHTML = src
                ? `<img src="${src}" class="sc-img" alt="${sc.name}"><div class="sc-inv-name">${sc.name}</div>`
                : `<div class="sc-inv-emoji">🔫</div><div class="sc-inv-name">${sc.name}</div>`;
        } else {
            content.innerHTML = '<div class="sc-inv-empty">Glisser une arme</div>';
        }
    });
}

// ══ DRAG CUSTOM — style coffre (ghost fixe, rects en cache) ══

// Ghost element fixe dans le body (cree une seule fois)
const invGhost = (() => {
    const g = document.createElement('div');
    g.className = 'drag-ghost hidden';
    g.innerHTML = '<img class="ghost-img" id="invGhostImg" src="" alt=""><div class="ghost-name" id="invGhostName"></div>';
    document.body.appendChild(g);
    return g;
})();
const invGhostImg  = document.getElementById('invGhostImg');
const invGhostName = document.getElementById('invGhostName');

// Cache des rects shortcut slots (calcule une seule fois par drag)
let scRects = [];

function startDrag(e, weapon, originEl) {
    dragItem     = weapon;
    dragOriginEl = originEl;
    originEl.classList.add('dragging');

    // Ghost
    const src = getImg(weapon.name);
    if (src) { invGhostImg.src = src; invGhostImg.style.display = ''; }
    else      { invGhostImg.style.display = 'none'; }
    invGhostName.textContent = weapon.name;
    moveGhost(e);
    invGhost.classList.remove('hidden');

    // Cache rects des slots shortcut — forcer reflow avant getBoundingClientRect
    scRects = [];
    void shortcutGrid.offsetHeight; // force reflow
    shortcutGrid.querySelectorAll('.sc-inv-slot').forEach(s => {
        s.classList.add('drop-ready');
        scRects.push({ el: s, r: s.getBoundingClientRect() });
    });
}

function moveGhost(e) {
    invGhost.style.left = (e.clientX + 14) + 'px';
    invGhost.style.top  = (e.clientY + 14) + 'px';
}

function cancelDrag() {
    invGhost.classList.add('hidden');
    if (dragOriginEl) { dragOriginEl.classList.remove('dragging'); dragOriginEl = null; }
    scRects.forEach(({ el }) => el.classList.remove('drop-ready', 'dragover'));
    scRects = [];
    dragItem = null;
}

document.addEventListener('mousemove', e => {
    if (!dragItem) return;
    moveGhost(e);
    // Highlight le slot sous la souris
    scRects.forEach(({ el, r }) => {
        el.classList.toggle('dragover',
            e.clientX >= r.left && e.clientX <= r.right &&
            e.clientY >= r.top  && e.clientY <= r.bottom
        );
    });
});

document.addEventListener('mouseup', e => {
    if (!dragItem) return;

    // elementFromPoint = element réel sous la souris au relâcher
    // Plus fiable que les rects précalculés au mousedown
    invGhost.classList.add('hidden'); // cacher ghost pour que elementFromPoint fonctionne
    const target = document.elementFromPoint(e.clientX, e.clientY);
    invGhost.classList.remove('hidden');

    const slot = target && target.closest('.sc-inv-slot');
    if (slot) {
        const slotNum = parseInt(slot.dataset.slot);
        shortcuts[slotNum - 1] = { uuid: dragItem.uuid, hash: dragItem.hash, name: dragItem.name, cat: dragItem.cat };
        post('bindShortcut', { slot: slotNum, uuid: dragItem.uuid });
        cancelDrag();
        renderShortcutGrid();
    } else {
        cancelDrag();
    }
});

// Clic droit = vider slot
shortcutGrid.addEventListener('contextmenu', e => {
    e.preventDefault();
    const slot = e.target.closest('.sc-inv-slot');
    if (!slot) return;
    const n = parseInt(slot.dataset.slot);
    shortcuts[n - 1] = null;
    post('unbindShortcut', { slot: n });
    renderShortcutGrid();
});

// Clic slot rempli = équiper / déséquiper (toggle)
shortcutGrid.addEventListener('click', e => {
    if (dragItem) return;
    const slot = e.target.closest('.sc-inv-slot');
    if (!slot) return;
    const n  = parseInt(slot.dataset.slot);
    const sc = shortcuts[n - 1];
    if (sc) {
        // Toggle : envoie shortcutKey qui gère equip/unequip côté Lua
        post('shortcutKey', { slot: n });
        closeInventory();
    }
});

// ══ EVENTS DÉLÉGUÉS ══
weaponsGrid.addEventListener('click', e => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const i = parseInt(btn.dataset.index);
    const w = weaponsData[i];
    if (btn.dataset.action === 'equip') {
        post('equipWeapon', { uuid: w.uuid });
        showNotif(`🔫 ${w.name} équipé`, 'info');
        closeInventory();
    } else if (btn.dataset.action === 'drop') {
        post('dropWeapon', { uuid: w.uuid });
        showNotif(`🗑 ${w.name} jeté`, 'error');
        // Nettoie le shortcut JS si bindé
        for (let s = 0; s < 5; s++) { if (shortcuts[s]?.uuid === w.uuid) shortcuts[s] = null; }
        weaponsData.splice(i, 1);
        selectedWeapon = null;
        bagWeight.textContent = weaponsData.length + ' arme(s)';
        renderWeapons(); renderTradeGrid(); renderShortcutGrid();
    }
});

tradeGrid.addEventListener('click', e => {
    const card = e.target.closest('.item-card');
    if (!card) return;
    selectedWeapon = weaponsData[parseInt(card.dataset.index)];
    tradeGrid.querySelectorAll('.item-card').forEach(c => c.classList.remove('selected'));
    card.classList.add('selected');
    checkAction();
});

playersList.addEventListener('click', e => {
    const row = e.target.closest('.player-row');
    if (!row) return;
    selectedPlayer = playersData[parseInt(row.dataset.index)];
    playersList.querySelectorAll('.player-row').forEach(r => r.classList.remove('selected'));
    row.classList.add('selected');
    checkAction();
});

function checkAction() {
    if (selectedWeapon && selectedPlayer) {
        actionWname.textContent = selectedWeapon.name;
        actionPname.textContent = selectedPlayer.name;
        actionBox.classList.remove('hidden');
    }
}

function renderPlayers() {
    if (!playersData.length) {
        playersList.innerHTML = '<div class="empty-msg">Aucun joueur à portée</div>';
        return;
    }
    const frag = document.createDocumentFragment();
    playersData.forEach((p, i) => {
        const d = document.createElement('div');
        d.className = 'player-row';
        d.dataset.index = i;
        d.innerHTML = `<div class="pr-avatar">👤</div><div class="pr-name">${p.name}</div><div class="pr-dist">${p.dist}m</div>`;
        frag.appendChild(d);
    });
    playersList.innerHTML = '';
    playersList.appendChild(frag);
}

$('giveBtn').addEventListener('click', () => {
    if (!selectedWeapon || !selectedPlayer) return;
    post('giveWeapon', { targetId: selectedPlayer.id, uuid: selectedWeapon.uuid });
    showNotif(`🎁 ${selectedWeapon.name} donné à ${selectedPlayer.name}`, 'success');
    closeInventory();
});

$('tradeBtn').addEventListener('click', () => {
    if (!selectedWeapon || !selectedPlayer) return;
    post('requestTrade', { targetId: selectedPlayer.id, uuid: selectedWeapon.uuid });
    showNotif(`🔄 Demande envoyée à ${selectedPlayer.name}…`, 'info');
    actionBox.classList.add('hidden');
});

$('cancelBtn').addEventListener('click', () => {
    selectedWeapon = null; selectedPlayer = null;
    tradeGrid.querySelectorAll('.item-card').forEach(c => c.classList.remove('selected'));
    playersList.querySelectorAll('.player-row').forEach(r => r.classList.remove('selected'));
    actionBox.classList.add('hidden');
});

function showTradeModal(data) {
    currentTradeId = data.tradeId;
    tmFrom.textContent   = data.fromName;
    tmWeapon.textContent = data.weaponName;
    tradeModal.classList.remove('hidden');
}
function hideTradeModal() { tradeModal.classList.add('hidden'); currentTradeId = null; }

$('acceptBtn').addEventListener('click', () => {
    if (!currentTradeId) return;
    post('acceptTrade', { tradeId: currentTradeId }); hideTradeModal();
});
$('declineBtn').addEventListener('click', () => {
    if (!currentTradeId) return;
    post('declineTrade', { tradeId: currentTradeId }); hideTradeModal();
    showNotif('Trade refusé.', 'error');
});

function showNotif(msg, type = 'info') {
    if (notifQ.length >= 5) { notifQ[0].remove(); notifQ.shift(); }
    const el = document.createElement('div');
    el.className = `notif ${type}`; el.textContent = msg;
    notifsEl.appendChild(el); notifQ.push(el);
    setTimeout(() => { el.remove(); notifQ = notifQ.filter(n => n !== el); }, 4000);
}
