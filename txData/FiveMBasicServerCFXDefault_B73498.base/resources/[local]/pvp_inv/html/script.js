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

// ── SVG icons embarqués ──
function makeSVG(paths, vb='0 0 64 64') {
    return `data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='${vb}'>${paths}</svg>`;
}
const W = "fill='%23c8cdd6'";
const D = "fill='%23333'";

const weaponImages = {
    'Pistolet':           makeSVG(`<rect x='8' y='26' width='40' height='14' rx='3' ${W}/><rect x='38' y='18' width='12' height='12' rx='2' ${W}/><rect x='8' y='38' width='10' height='10' rx='1' ${D}/><rect x='48' y='28' width='8' height='4' rx='1' ${D}/>`),
    'Pistolet MK2':       makeSVG(`<rect x='6' y='25' width='42' height='14' rx='3' ${W}/><rect x='38' y='16' width='12' height='13' rx='2' ${W}/><rect x='6' y='37' width='10' height='11' rx='1' ${D}/><rect x='48' y='27' width='10' height='4' rx='1' ${D}/><rect x='10' y='39' width='20' height='3' rx='1' fill='%23e53935'/>`),
    'Pistolet Combat':    makeSVG(`<rect x='8' y='26' width='38' height='13' rx='2' ${W}/><rect x='36' y='18' width='12' height='11' rx='2' ${W}/><rect x='8' y='37' width='10' height='10' rx='1' ${D}/><rect x='46' y='27' width='8' height='3' rx='1' ${D}/>`),
    'Pistolet AP':        makeSVG(`<rect x='6' y='24' width='44' height='14' rx='3' ${W}/><rect x='40' y='15' width='12' height='13' rx='2' ${W}/><rect x='6' y='36' width='12' height='12' rx='1' ${D}/><rect x='50' y='26' width='10' height='4' rx='1' ${D}/>`),
    'Pistolet Lourd':     makeSVG(`<rect x='6' y='24' width='46' height='16' rx='3' ${W}/><rect x='40' y='14' width='14' height='14' rx='2' ${W}/><rect x='6' y='38' width='14' height='12' rx='1' ${D}/><rect x='52' y='26' width='10' height='5' rx='1' ${D}/>`),
    'Pistolet SNS':       makeSVG(`<rect x='10' y='28' width='34' height='11' rx='2' ${W}/><rect x='34' y='21' width='12' height='10' rx='2' ${W}/><rect x='10' y='37' width='9' height='9' rx='1' ${D}/><rect x='44' y='29' width='7' height='3' rx='1' ${D}/>`),
    'Micro SMG':          makeSVG(`<rect x='4' y='26' width='48' height='12' rx='2' ${W}/><rect x='36' y='18' width='10' height='10' rx='2' ${W}/><rect x='4' y='36' width='8' height='10' rx='1' ${D}/><rect x='50' y='28' width='12' height='4' rx='1' ${D}/>`),
    'SMG':                makeSVG(`<rect x='2' y='25' width='52' height='14' rx='3' ${W}/><rect x='34' y='16' width='12' height='11' rx='2' ${W}/><rect x='2' y='37' width='10' height='12' rx='1' ${D}/><rect x='52' y='27' width='12' height='4' rx='1' ${D}/>`),
    'SMG MK2':            makeSVG(`<rect x='2' y='24' width='52' height='14' rx='3' ${W}/><rect x='34' y='15' width='12' height='11' rx='2' ${W}/><rect x='2' y='36' width='10' height='13' rx='1' ${D}/><rect x='2' y='38' width='52' height='3' rx='1' fill='%23e53935'/>`),
    'SMG Assault':        makeSVG(`<rect x='2' y='24' width='54' height='14' rx='3' ${W}/><rect x='38' y='15' width='12' height='11' rx='2' ${W}/><rect x='2' y='36' width='10' height='13' rx='1' ${D}/>`),
    'PDW Combat':         makeSVG(`<rect x='2' y='26' width='48' height='12' rx='3' ${W}/><rect x='32' y='18' width='12' height='10' rx='2' ${W}/><rect x='2' y='36' width='10' height='11' rx='1' ${D}/>`),
    "Fusil d'assaut":     makeSVG(`<rect x='0' y='26' width='64' height='13' rx='2' ${W}/><rect x='38' y='18' width='10' height='10' rx='2' ${W}/><rect x='10' y='37' width='10' height='13' rx='1' ${D}/><rect x='54' y='24' width='10' height='4' rx='1' ${D}/>`),
    "Fusil d'assaut MK2": makeSVG(`<rect x='0' y='25' width='64' height='14' rx='2' ${W}/><rect x='38' y='17' width='10' height='10' rx='2' ${W}/><rect x='10' y='37' width='10' height='13' rx='1' ${D}/><rect x='0' y='39' width='64' height='3' rx='1' fill='%23e53935'/>`),
    'Carabine':           makeSVG(`<rect x='0' y='26' width='64' height='13' rx='2' ${W}/><rect x='36' y='18' width='10' height='10' rx='2' ${W}/><rect x='12' y='37' width='10' height='13' rx='1' ${D}/>`),
    'Carabine MK2':       makeSVG(`<rect x='0' y='25' width='64' height='14' rx='2' ${W}/><rect x='36' y='17' width='10' height='10' rx='2' ${W}/><rect x='12' y='37' width='10' height='13' rx='1' ${D}/><rect x='0' y='39' width='64' height='3' fill='%23e53935'/>`),
    'Fusil Avancé':       makeSVG(`<rect x='0' y='26' width='64' height='12' rx='2' ${W}/><rect x='40' y='18' width='10' height='10' rx='2' ${W}/><rect x='14' y='36' width='8' height='12' rx='1' ${D}/>`),
    'Carabine Spéciale':  makeSVG(`<rect x='0' y='26' width='62' height='13' rx='2' ${W}/><rect x='36' y='18' width='10' height='10' rx='2' ${W}/><rect x='12' y='37' width='10' height='13' rx='1' ${D}/>`),
    'Bullpup Rifle':      makeSVG(`<rect x='0' y='24' width='64' height='16' rx='3' ${W}/><rect x='48' y='16' width='14' height='12' rx='2' ${W}/><rect x='40' y='38' width='14' height='12' rx='1' ${D}/>`),
    'Sniper':             makeSVG(`<rect x='0' y='28' width='64' height='10' rx='2' ${W}/><rect x='42' y='20' width='8' height='10' rx='1' ${W}/><rect x='18' y='36' width='8' height='14' rx='1' ${D}/><circle cx='46' cy='22' r='5' fill='none' stroke='%23aaa' stroke-width='2'/>`),
    'Sniper Lourd':       makeSVG(`<rect x='0' y='27' width='64' height='12' rx='2' ${W}/><rect x='44' y='18' width='10' height='11' rx='1' ${W}/><rect x='16' y='37' width='10' height='14' rx='1' ${D}/><circle cx='48' cy='21' r='6' fill='none' stroke='%23aaa' stroke-width='2'/>`),
    'Sniper Lourd MK2':   makeSVG(`<rect x='0' y='26' width='64' height='13' rx='2' ${W}/><rect x='44' y='17' width='10' height='11' rx='1' ${W}/><rect x='16' y='37' width='10' height='14' rx='1' ${D}/><rect x='0' y='39' width='64' height='3' fill='%23e53935'/><circle cx='48' cy='20' r='6' fill='none' stroke='%23aaa' stroke-width='2'/>`),
    'Fusil Précision':    makeSVG(`<rect x='0' y='28' width='62' height='10' rx='2' ${W}/><rect x='40' y='20' width='8' height='10' rx='1' ${W}/><rect x='18' y='36' width='8' height='12' rx='1' ${D}/><circle cx='44' cy='23' r='4' fill='none' stroke='%23aaa' stroke-width='2'/>`),
    'Shotgun Pompe':      makeSVG(`<rect x='0' y='26' width='56' height='14' rx='2' ${W}/><rect x='36' y='38' width='16' height='10' rx='1' ${D}/><rect x='56' y='24' width='8' height='5' rx='1' ${D}/>`),
    'Shotgun Scié':       makeSVG(`<rect x='4' y='26' width='44' height='14' rx='2' ${W}/><rect x='30' y='38' width='14' height='10' rx='1' ${D}/><rect x='46' y='24' width='8' height='5' rx='1' ${D}/>`),
    'Shotgun Assault':    makeSVG(`<rect x='0' y='24' width='56' height='16' rx='3' ${W}/><rect x='36' y='15' width='10' height='11' rx='2' ${W}/><rect x='10' y='38' width='10' height='14' rx='1' ${D}/>`),
    'Shotgun Bullpup':    makeSVG(`<rect x='0' y='23' width='64' height='18' rx='3' ${W}/><rect x='50' y='15' width='12' height='10' rx='2' ${W}/><rect x='44' y='39' width='16' height='14' rx='1' ${D}/>`),
    'Shotgun Lourd':      makeSVG(`<rect x='0' y='23' width='58' height='18' rx='3' ${W}/><rect x='38' y='14' width='12' height='11' rx='2' ${W}/><rect x='10' y='39' width='12' height='14' rx='1' ${D}/>`),
    'Lance-grenades':     makeSVG(`<rect x='2' y='24' width='52' height='18' rx='4' ${W}/><rect x='18' y='40' width='12' height='14' rx='1' ${D}/><circle cx='54' cy='31' r='6' fill='%23777'/>`),
    'RPG':                makeSVG(`<rect x='0' y='28' width='50' height='10' rx='2' ${W}/><rect x='50' y='24' width='14' height='18' rx='3' fill='%23888'/><rect x='18' y='36' width='10' height='14' rx='1' ${D}/><polygon points='64,32 58,26 58,38' fill='%23e53935'/>`),
    'Minigun':            makeSVG(`<circle cx='32' cy='32' r='14' ${W}/><circle cx='32' cy='32' r='8' ${D}/><rect x='46' y='30' width='18' height='4' rx='2' ${D}/>`),
    'Grenade':            makeSVG(`<circle cx='30' cy='36' r='16' fill='%23556b2f'/><rect x='27' y='16' width='6' height='10' rx='2' fill='%23888'/><rect x='22' y='12' width='16' height='6' rx='2' fill='%23777'/>`),
    'Grenade Fumigène':   makeSVG(`<circle cx='32' cy='38' r='14' fill='%23607d8b'/><rect x='29' y='20' width='6' height='10' rx='2' fill='%23888'/><circle cx='32' cy='16' r='4' fill='%23aaa'/>`),
    'Molotov':            makeSVG(`<rect x='26' y='30' width='12' height='24' rx='4' fill='%23c8a040'/><rect x='28' y='14' width='8' height='18' rx='2' fill='%23aaa'/><polygon points='32,4 26,16 38,16' fill='%23e53935'/>`),
    'Couteau':            makeSVG(`<polygon points='10,50 20,54 54,20 50,10' ${W}/><polygon points='10,50 14,56 20,54' ${D}/>`),
    'Batte':              makeSVG(`<rect x='28' y='4' width='8' height='44' rx='4' fill='%23c8a040'/><rect x='26' y='46' width='12' height='14' rx='3' fill='%23888'/>`),
    'Coup de Poing':      makeSVG(`<rect x='8' y='24' width='48' height='28' rx='8' fill='%23d4a040'/><rect x='12' y='18' width='10' height='14' rx='4' fill='%23d4a040'/><rect x='26' y='18' width='10' height='14' rx='4' fill='%23d4a040'/><rect x='40' y='18' width='10' height='14' rx='4' fill='%23d4a040'/>`),
};

function getImg(name) { return weaponImages[name] || null; }

function imgHTML(name) {
    const src = getImg(name);
    return src
        ? `<img src="${src}" class="item-img" alt="${name}">`
        : `<div class="item-fallback">🔫</div>`;
}

// ══ NUI messages ══
window.addEventListener('message', ({ data }) => {
    switch (data.action) {
        case 'openInventory': openInventory(data);                              break;
        case 'notification':  showNotif(data.msg, data.ntype || 'info');        break;
        case 'tradeRequest':  showTradeModal(data);                             break;
        case 'tradeAccepted':
        case 'tradeDeclined': hideTradeModal();                                 break;
    }
});

const post = (ep, body = {}) => fetch(`https://pvp_inv/${ep}`, {
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
                shortcuts[slot - 1] = { hash: w.hash, name: w.name, cat: w.cat };
                post('bindShortcut', { slot, hash: w.hash });
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
                <span class="item-fname">${w.name}</span>
                <span class="item-qty">x${w.ammo}</span>
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
        d.innerHTML = `${imgHTML(w.name)}<div class="item-footer"><span class="item-fname">${w.name}</span><span class="item-qty">x${w.ammo}</span></div>`;
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
        shortcuts[slotNum - 1] = { hash: dragItem.hash, name: dragItem.name, cat: dragItem.cat };
        post('bindShortcut', { slot: slotNum, hash: dragItem.hash });
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
        post('equipWeapon', { hash: w.hash });
        showNotif(`🔫 ${w.name} équipé`, 'info');
        closeInventory();
    } else if (btn.dataset.action === 'drop') {
        post('dropWeapon', { hash: w.hash });
        showNotif(`🗑 ${w.name} jeté`, 'error');
        // Nettoie le shortcut JS si bindé
        for (let s = 0; s < 5; s++) { if (shortcuts[s]?.hash === w.hash) shortcuts[s] = null; }
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
    post('giveWeapon', { targetId: selectedPlayer.id, hash: selectedWeapon.hash, ammo: selectedWeapon.ammo });
    showNotif(`🎁 ${selectedWeapon.name} donné à ${selectedPlayer.name}`, 'success');
    closeInventory();
});

$('tradeBtn').addEventListener('click', () => {
    if (!selectedWeapon || !selectedPlayer) return;
    post('requestTrade', { targetId: selectedPlayer.id, hash: selectedWeapon.hash, ammo: selectedWeapon.ammo });
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
