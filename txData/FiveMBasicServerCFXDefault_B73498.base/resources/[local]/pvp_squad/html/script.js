'use strict';

const $ = id => document.getElementById(id);

// DOM
const appEl = $('app');
const squadHUD = $('squadHUD');
const squadTab = $('squadTab');
const hudSquadName = $('hudSquadName');
const hudMembers = $('hudMembers');
const tabLabel = $('tabLabel');
const noSquad = $('noSquad');
const mySquadPanel = $('mySquadPanel');
const mySquadName = $('mySquadName');
const mySquadSlots = $('mySquadSlots');
const visToggle = $('visibilityToggle');
const visLabel = $('visLabel');
const hudToggle = $('hudToggle');
const myMembersList = $('myMembersList');
const squadsList = $('squadsList');
const createModal = $('createModal');
const requestModal = $('requestModal');
const notifsEl = $('notifs');

let mySquad = null;
let myServerId = 0;
let allSquads = [];
let pendingRequest = null; // { requesterSrc, requesterName }
let showHUD = true;
let notifQ = [];

// ── NUI messages ──
window.addEventListener('message', ({ data }) => {
    switch (data.action) {
        case 'open': onOpen(data); break;
        case 'close': appEl.classList.add('hidden'); break;
        case 'squadList': onSquadList(data.squads); break;
        case 'mySquad': onMySquad(data.squad, data.show); break;
        case 'joinRequest': onJoinRequest(data); break;
        case 'notification': showNotif(data.msg, data.ntype || 'info'); break;
        case 'setHUD': updateHUDVisibility(data.show); break;
    }
});

const post = (ep, body = {}) => fetch(`https://pvp_squad/${ep}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
});

// ── Touche J (détectée dans NUI) ──
document.addEventListener('keydown', e => {
    if (e.key === 'j' || e.key === 'J') {
        if (!appEl.classList.contains('hidden')) {
            closeMenu();
        } else {
            post('keyJ');
        }
    }
    if (e.key === 'Escape' && !appEl.classList.contains('hidden')) {
        closeMenu();
    }
});

function closeMenu() {
    appEl.classList.add('hidden');
    post('close');
}

// ── OPEN ──
function onOpen(data) {
    myServerId = data.myServerId || 0;
    if (data.mySquad) onMySquad(data.mySquad, true);
    appEl.classList.remove('hidden');
}

// ── MA SQUAD ──
function onMySquad(squadData, hudVisible) {
    mySquad = squadData;

    if (hudVisible !== undefined) showHUD = hudVisible !== false;

    if (!mySquad) {
        noSquad.classList.remove('hidden');
        mySquadPanel.classList.add('hidden');
        updateHUD(null);
        return;
    }

    noSquad.classList.add('hidden');
    mySquadPanel.classList.remove('hidden');

    mySquadName.textContent = mySquad.name;
    mySquadSlots.textContent = mySquad.slots;

    // Toggle visibilité (seulement pour le leader)
    visToggle.checked = mySquad.isPublic;
    visLabel.textContent = mySquad.isPublic ? 'Publique' : 'Privée';
    const isLeader = mySquad.leader === myServerId;
    visToggle.disabled = !isLeader;

    renderMyMembers();
    updateHUD(mySquad);
}

function renderMyMembers() {
    if (!mySquad) return;
    const frag = document.createDocumentFragment();
    mySquad.members.forEach(m => {
        const isLeader = m.id === mySquad.leader;
        const isMe = m.id === myServerId;
        const amLeader = mySquad.leader === myServerId;

        const d = document.createElement('div');
        d.className = 'member-row';
        d.innerHTML = `
            <div class="member-dot ${isLeader ? 'leader' : ''}"></div>
            <div class="member-name">${m.name}${isMe ? ' (vous)' : ''}</div>
            ${isLeader ? '<span class="member-crown">👑</span>' : ''}
            ${amLeader && !isMe ? `<button class="kick-btn" data-src="${m.id}">EXCLURE</button>` : ''}`;
        frag.appendChild(d);
    });
    myMembersList.innerHTML = '';
    myMembersList.appendChild(frag);
}

// ── HUD ──
function updateHUD(squad) {
    if (!squad || !showHUD) {
        squadHUD.classList.add('hidden');
        if (squad && !showHUD) {
            squadTab.classList.remove('hidden');
            tabLabel.textContent = squad.name;
        } else {
            squadTab.classList.add('hidden');
        }
        return;
    }

    squadHUD.classList.remove('hidden');
    squadTab.classList.add('hidden');
    hudSquadName.textContent = squad.name;

    const frag = document.createDocumentFragment();
    squad.members.forEach(m => {
        const isLeader = m.id === squad.leader;
        const d = document.createElement('div');
        d.className = 'hud-member';
        d.innerHTML = `
            <div class="hud-dot ${isLeader ? 'leader' : ''}"></div>
            <div class="hud-mname">${m.name}</div>
            ${isLeader ? '<span class="hud-crown">👑</span>' : ''}`;
        frag.appendChild(d);
    });
    hudMembers.innerHTML = '';
    hudMembers.appendChild(frag);
}

function updateHUDVisibility(show) {
    showHUD = show;
    updateHUD(mySquad);
}

// HUD hide button
$('hudHideBtn').addEventListener('click', () => {
    showHUD = false;
    updateHUD(mySquad);
    post('toggleHUD', { show: false });
});

// Tab click = réafficher HUD
squadTab.addEventListener('click', () => {
    showHUD = true;
    updateHUD(mySquad);
    post('toggleHUD', { show: true });
    hudToggle.checked = true;
});

// ── SQUADS LIST ──
function onSquadList(squads) {
    allSquads = squads || [];
    renderSquadList();
}

function renderSquadList() {
    if (!allSquads.length) {
        squadsList.innerHTML = '<div class="empty-state">Aucune squad disponible</div>';
        return;
    }

    const frag = document.createDocumentFragment();
    allSquads.forEach(squad => {
        const isFull = squad.slots >= squad.maxSlots;
        const inSquad = !!mySquad;

        const d = document.createElement('div');
        d.className = 'squad-card';

        const pct = Math.round((squad.slots / squad.maxSlots) * 100);
        let badgeHtml = isFull
            ? `<span class="badge full">COMPLET</span>`
            : squad.isPublic
                ? `<span class="badge public">PUBLIC</span>`
                : `<span class="badge private">PRIVÉ</span>`;

        let actionHtml = '';
        if (!inSquad && !isFull) {
            if (squad.isPublic) {
                actionHtml = `<button class="btn-join"    data-id="${squad.id}">REJOINDRE</button>`;
            } else {
                actionHtml = `<button class="btn-request" data-id="${squad.id}">DEMANDER</button>`;
            }
        }

        d.innerHTML = `
            <div class="squad-card-top">
                <div class="squad-card-name">${squad.name}</div>
                ${badgeHtml}
            </div>
            <div class="squad-card-slots">${squad.slots}/${squad.maxSlots} membres</div>
            <div class="slots-bar"><div class="slots-fill" style="width:${pct}%"></div></div>
            ${actionHtml ? `<div class="squad-card-actions">${actionHtml}</div>` : ''}`;

        frag.appendChild(d);
    });

    squadsList.innerHTML = '';
    squadsList.appendChild(frag);
}

// Délégation sur la liste
squadsList.addEventListener('click', e => {
    const joinBtn = e.target.closest('.btn-join');
    const requestBtn = e.target.closest('.btn-request');
    if (joinBtn) post('joinSquad', { squadId: parseInt(joinBtn.dataset.id) });
    if (requestBtn) post('requestJoin', { squadId: parseInt(requestBtn.dataset.id) });
});

// Délégation sur les membres
myMembersList.addEventListener('click', e => {
    const btn = e.target.closest('.kick-btn');
    if (btn) post('kickMember', { targetSrc: parseInt(btn.dataset.src) });
});

// ── CRÉER SQUAD ──
$('createBtn').addEventListener('click', () => {
    createModal.classList.remove('hidden');
    $('squadNameInput').focus();
});

$('confirmCreate').addEventListener('click', () => {
    const name = $('squadNameInput').value.trim() || 'Ma Squad';
    const isPublic = document.querySelector('input[name="vis"]:checked').value === 'public';
    post('createSquad', { name, isPublic });
    createModal.classList.add('hidden');
    $('squadNameInput').value = '';
});

$('cancelCreate').addEventListener('click', () => {
    createModal.classList.add('hidden');
    $('squadNameInput').value = '';
});

// Enter dans le champ = confirmer
$('squadNameInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') $('confirmCreate').click();
});

// ── TOGGLES ──
visToggle.addEventListener('change', () => {
    visLabel.textContent = visToggle.checked ? 'Publique' : 'Privée';
    post('setVisibility', { isPublic: visToggle.checked });
});

hudToggle.addEventListener('change', () => {
    showHUD = hudToggle.checked;
    updateHUD(mySquad);
    post('toggleHUD', { show: showHUD });
});

// ── QUITTER ──
$('leaveBtn').addEventListener('click', () => {
    post('leaveSquad');
});

// ── CLOSE ──
$('closeBtn').addEventListener('click', closeMenu);

// ── JOIN REQUEST ──
function onJoinRequest(data) {
    pendingRequest = { requesterSrc: data.requesterSrc, requesterName: data.requesterName };
    $('reqName').textContent = data.requesterName;
    requestModal.classList.remove('hidden');
}

$('acceptReqBtn').addEventListener('click', () => {
    if (!pendingRequest) return;
    post('acceptJoin', { targetSrc: pendingRequest.requesterSrc });
    requestModal.classList.add('hidden');
    pendingRequest = null;
});

$('declineReqBtn').addEventListener('click', () => {
    requestModal.classList.add('hidden');
    pendingRequest = null;
});

// ── NOTIFICATIONS ──
function showNotif(msg, type = 'info') {
    if (notifQ.length >= 5) { notifQ[0].remove(); notifQ.shift(); }
    const el = document.createElement('div');
    el.className = `notif ${type}`;
    el.textContent = msg;
    notifsEl.appendChild(el);
    notifQ.push(el);
    setTimeout(() => { el.remove(); notifQ = notifQ.filter(n => n !== el); }, 4000);
}
