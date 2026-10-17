// Reactive State Management
const STATE = {
  currentUser: null,
  currentWallet: null,
  currentTab: 'home',
  adminSubTab: 'overview',
  allUsers: [],
  games: [],
  packages: [],
  tournaments: [],
  myMatches: [],
  orders: [],
  selectedGame: null,
  selectedPackage: null,
  selectedPaymentMethod: 'wallet',
  topUpMode: 'wallet', // 'wallet' (Screen 1) or 'catalog' (Screen 9) or 'game' (Screen 8)
  txFilter: 'All', // 'All', 'Top Up', 'Withdraw', 'Games'
  selectedCountry: null, // Localized country & currency config

  listeners: new Set(),

  subscribe(fn) {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  },

  notify(event, payload) {
    for (const fn of this.listeners) {
      try { fn(event, payload); } catch (e) { console.error('State listener error', e); }
    }
  },

  async init() {
    try {
      const meData = await API.getMe();
      this.currentUser = meData.user;
      this.currentWallet = meData.wallet;

      this.allUsers = await API.getUsers();
      this.games = await API.getGames();
      if (this.games.length > 0) {
        this.selectedGame = this.games[0];
        this.packages = await API.getPackages(this.games[0].id);
        if (this.packages.length > 0) {
          this.selectedPackage = this.packages[0];
        }
      }

      this.notify('INIT_COMPLETE');
    } catch (err) {
      console.error('Failed to init state:', err);
    }
  },

  async refreshWallet() {
    try {
      this.currentWallet = await API.getWallet();
      this.notify('WALLET_UPDATED', this.currentWallet);
    } catch (err) {
      console.error('Error refreshing wallet:', err);
    }
  },

  setTab(tab) {
    this.currentTab = tab;
    this.notify('TAB_CHANGED', tab);
  },

  setAdminSubTab(subTab) {
    this.adminSubTab = subTab;
    this.notify('ADMIN_SUBTAB_CHANGED', subTab);
  },

  async switchUser(userId) {
    try {
      const res = await API.switchUser(userId);
      this.currentUser = res.user;
      this.currentWallet = res.wallet;
      API.setAuthToken(userId);
      this.notify('USER_SWITCHED', res.user);
      Toast.show(`Switched session to ${res.user.display_name} (${res.user.role})`, 'info');
    } catch (err) {
      Toast.show('Error switching user: ' + err.message, 'error');
    }
  }
};

// Global Toast Manager
const Toast = {
  container: null,

  init() {
    this.container = document.getElementById('toast-container');
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.id = 'toast-container';
      this.container.className = 'toast-container';
      document.body.appendChild(this.container);
    }
  },

  show(message, type = 'info', duration = 4000) {
    if (!this.container) this.init();

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;

    const icons = {
      success: '✅',
      error: '❌',
      info: '⚡'
    };

    toast.innerHTML = `
      <span style="font-size: 1.2rem;">${icons[type] || '⚡'}</span>
      <div style="flex: 1; font-size: 0.9rem; line-height: 1.4;">${message}</div>
    `;

    this.container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, duration);
  }
};

function formatRs(amount) {
  const num = Number(amount) || 0;
  return `Rs. ${num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

window.STATE = STATE;
window.Toast = Toast;
window.formatRs = formatRs;
