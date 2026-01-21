// raytrix playergoal - store look

const state = {
    currentData: null,
    isVisible: false,
    menuData: null
};

document.addEventListener('DOMContentLoaded', () => {
    bindButtons();
});

window.addEventListener('message', (event) => {
    const { action, data, goal, command } = event.data;

    const handlers = {
        show: showUI,
        hide: hideUI,
        toggleOn: () => toggleUI(true),
        toggleOff: () => toggleUI(false),
        update: () => updateGoal(data),
        goalCompleted: () => showCelebration(goal),
        allCompleted: showAllCompleted,
        showRewards: () => animateRewards(),
        commandHint: () => setCommandHint(command),
        openMenu: () => openMenu(data),
        closeMenu: closeMenu,
        claimResult: () => handleClaimResult(data),
        toast: () => pulseFooter()
    };

    const handler = handlers[action];
    if (handler) {
        handler();
    }
});

function bindButtons() {
    const closeBtn = document.getElementById('closeMenu');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => postNui('closeMenu'));
    }
}

function postNui(name, body = {}) {
    fetch(`https://raytrix_playergoal/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(body)
    });
}

function showUI() {
    const container = document.getElementById('goalContainer');
    if (!state.isVisible && container) {
        container.classList.add('show');
        state.isVisible = true;
    }
}

function hideUI() {
    const container = document.getElementById('goalContainer');
    if (state.isVisible && container) {
        container.classList.remove('show');
        state.isVisible = false;
    }
}

function toggleUI(forceShow) {
    if (forceShow) {
        showUI();
        if (state.currentData) updateGoal(state.currentData);
    } else {
        hideUI();
    }
}

function updateGoal(data) {
    if (!data) return;
    state.currentData = data;

    updateText('currentPlayers', data.current ?? 0);
    updateText('requiredPlayers', data.required ?? 0);

    const label = document.getElementById('goalLabel');
    if (label) label.textContent = data.goal?.label || '20 Spelers bereikt';

    const required = Number(data.required) || 0;
    const progress = required > 0 ? Math.min((data.current / required) * 100, 100) : 100;
    setProgress(progress);

    updateClaimBadge(data.claimable);

    if (data.goal && data.goal.rewards) {
        renderRewards(data.goal.rewards);
    } else {
        renderRewards([]);
    }
}

function updateText(id, value) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = value;
}

function setProgress(percent) {
    const bar = document.getElementById('progressBar');
    const text = document.getElementById('progressText');

    if (bar) bar.style.width = `${Math.round(percent)}%`;
    if (text) text.textContent = `${Math.round(percent)}%`;
}

function updateClaimBadge(claimable) {
    const badge = document.getElementById('claimState');
    if (!badge) return;

    if (claimable) {
        badge.classList.remove('warning');
        badge.innerHTML = `
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <path d="M20 6L9 17L4 12" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            <span>Claimbaar</span>
        `;
    } else {
        badge.classList.add('warning');
        badge.innerHTML = `
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="2"/>
                <path d="M12 8V12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                <circle cx="12" cy="16" r="0.5" fill="currentColor" stroke="currentColor"/>
            </svg>
            <span>In Progress</span>
        `;
    }
}

function renderRewards(rewards) {
    const container = document.getElementById('rewardsList');
    if (!container) return;
    container.innerHTML = '';

    if (!rewards.length) {
        container.innerHTML = '<div style="text-align: center; color: var(--muted); font-size: 12px; padding: 10px;">Beloningen verschijnen zodra een goal actief is</div>';
        return;
    }

    rewards.forEach((reward) => {
        const item = document.createElement('div');
        item.className = 'reward-item';
        item.innerHTML = `
            <div class="reward-left">
                <div class="reward-icon">${getRewardIcon(reward.type)}</div>
                <div class="reward-info">
                    <div class="label">${escapeHtml(reward.label)}</div>
                    <div class="sub">${getRewardCopy(reward)}</div>
                </div>
            </div>
            <div class="reward-right">
                <span class="tag ${reward.type === 'coins' ? 'coin' : ''}">×${reward.amount || 1}</span>
            </div>
        `;
        container.appendChild(item);
    });
}

function getRewardCopy(reward) {
    const mapping = {
        bank: 'Wordt gestort op je bank',
        cash: 'Contant uitbetaald',
        money: 'Contant uitbetaald',
        coins: 'Premium coins',
        item: 'Inventory item',
        default: 'Community beloning'
    };
    return mapping[reward.type] || mapping.default;
}

function getRewardIcon(type) {
    const icons = {
        bank: '<img src="../images/money.png" alt="Money" style="width: 22px; height: 22px; object-fit: contain; display: block;">',
        cash: '<img src="../images/money.png" alt="Money" style="width: 22px; height: 22px; object-fit: contain; display: block;">',
        money: '<img src="../images/money.png" alt="Money" style="width: 22px; height: 22px; object-fit: contain; display: block;">',
        coins: '<img src="../images/coins.png" alt="Coins" style="width: 22px; height: 22px; object-fit: contain; display: block;">',
        item: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><rect x="4" y="4" width="16" height="16" rx="3" stroke="currentColor" stroke-width="2.5"/><path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>',
        default: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="8" stroke="currentColor" stroke-width="2.5"/><path d="M12 8V12L15 14" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>'
    };
    return icons[type] || icons.default;
}

function showCelebration(goal) {
    const overlay = document.getElementById('celebrationOverlay');
    if (!overlay) return;
    overlay.classList.add('show');
    setTimeout(() => overlay.classList.remove('show'), 3200);
    animateRewards();
    pulseFooter();
}

function showAllCompleted() {
    showCelebration();
}

function animateRewards() {
    const rewards = document.getElementById('rewardsList');
    if (!rewards) return;
    rewards.classList.add('pulse');
    setTimeout(() => rewards.classList.remove('pulse'), 600);
}

function pulseFooter() {
    const footer = document.querySelector('.card-footer');
    if (!footer) return;
    footer.classList.add('pulse');
    setTimeout(() => footer.classList.remove('pulse'), 500);
}

function openMenu(payload) {
    state.menuData = payload;
    const overlay = document.getElementById('menuOverlay');
    const widget = document.getElementById('goalContainer');
    if (!overlay) return;

    document.body.classList.add('menu-open');
    overlay.classList.add('show');
    
    // Hide the small widget when menu opens
    if (widget) {
        widget.classList.remove('show');
    }

    updateText('menuCurrentPlayers', payload?.currentPlayers || 0);
    renderGoalList(payload?.goals || []);
}

function closeMenu() {
    const overlay = document.getElementById('menuOverlay');
    const widget = document.getElementById('goalContainer');
    if (!overlay) return;
    
    document.body.classList.remove('menu-open');
    overlay.classList.remove('show');
    
    // Show the small widget again when menu closes
    if (widget && state.isVisible) {
        widget.classList.add('show');
    }
}

function renderGoalList(goals) {
    const list = document.getElementById('goalList');
    const claimCopy = document.getElementById('menuClaimCopy');
    if (!list) return;

    list.innerHTML = '';

    const available = goals.filter(g => g.completed && !g.claimed).length;
    if (claimCopy) {
        claimCopy.textContent = available > 0 ? `${available} goal(s) claimbaar` : 'Nog niets te claimen';
    }

    goals.forEach(goal => {
        const tile = document.createElement('div');
        tile.className = 'goal-tile';

        const statusClass = goal.claimed ? 'claimed' : (goal.completed ? 'ready' : '');
        const statusLabel = goal.claimed ? 'Geclaimd' : (goal.completed ? 'Claimbaar' : 'Nog niet behaald');

        tile.innerHTML = `
            <div class="goal-top">
                <div>
                    <div class="goal-title">${escapeHtml(goal.label || `${goal.players} spelers`)} </div>
                    <div class="goal-meta">${goal.players} spelers nodig</div>
                </div>
                <div class="goal-status ${statusClass}">${statusLabel}</div>
            </div>
            <div class="goal-rewards"></div>
        `;

        const rewardsWrap = tile.querySelector('.goal-rewards');
        const rewards = goal.rewards || [];

        rewards.forEach((reward, index) => {
            const rewardTile = document.createElement('div');
            rewardTile.className = 'reward-tile';
            rewardTile.innerHTML = `
                <div class="reward-stack">
                    <div class="reward-icon">${getRewardIcon(reward.type)}</div>
                    <div>
                        <div class="label">${escapeHtml(reward.label)}</div>
                        <div class="sub">${getRewardCopy(reward)}</div>
                    </div>
                </div>
                <button class="claim-btn" ${goal.completed && !goal.claimed ? '' : 'disabled'} data-goal="${goal.players}" data-reward="${index}">
                    ${goal.completed && !goal.claimed ? 'Claim' : goal.claimed ? 'Geclaimd' : 'Locked'}
                </button>
            `;
            rewardsWrap.appendChild(rewardTile);
        });

        // Add filler info when there's only 1 reward
        if (rewards.length === 1) {
            const fillerInfo = document.createElement('div');
            fillerInfo.className = 'reward-filler-info';
            fillerInfo.innerHTML = `
                <div class="filler-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </div>
                <div class="filler-text">
                    <div class="filler-title">Exclusieve Community Beloning</div>
                    <div class="filler-sub">Bereik dit doel samen met de community</div>
                </div>
            `;
            rewardsWrap.appendChild(fillerInfo);
        }

        list.appendChild(tile);
    });

    list.querySelectorAll('.claim-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const goalPlayers = Number(e.currentTarget.getAttribute('data-goal'));
            const rewardIndex = Number(e.currentTarget.getAttribute('data-reward')) + 1; // Lua tables are 1-indexed

            if (e.currentTarget.disabled) return;
            postNui('claimReward', { goalPlayers, rewardIndex });
        });
    });
}

function handleClaimResult(result) {
    if (!result) return;

    if (result.success && state.menuData && Array.isArray(state.menuData.goals)) {
        state.menuData.goals = state.menuData.goals.map(goal => {
            if (goal.players === result.goalPlayers) {
                return { ...goal, claimed: true };
            }
            return goal;
        });
        renderGoalList(state.menuData.goals);
    }
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        postNui('closeMenu');
    }
});

function escapeHtml(text = '') {
    const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' };
    return String(text).replace(/[&<>"']/g, m => map[m]);
}
