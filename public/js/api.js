// API Client Layer
const API = {
  authToken: localStorage.getItem('topup_auth_token') || '',

  setAuthToken(token) {
    this.authToken = token;
    localStorage.setItem('topup_auth_token', token);
  },

  async request(path, options = {}) {
    const headers = {
      'Content-Type': 'application/json',
      'X-Auth-Token': this.authToken,
      ...(options.headers || {})
    };

    try {
      const res = await fetch(path, {
        ...options,
        headers
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.error || `HTTP ${res.status}: Request failed`);
      }
      return data;
    } catch (err) {
      console.error(`[API Error] ${options.method || 'GET'} ${path}:`, err);
      throw err;
    }
  },

  // Auth
  getMe() { return this.request('/api/auth/me'); },
  getUsers() { return this.request('/api/users'); },
  login(username, password) {
    return this.request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    });
  },
  switchUser(userId) {
    return this.request('/api/auth/switch-user', {
      method: 'POST',
      body: JSON.stringify({ userId })
    });
  },
  googleLogin(data) {
    return this.request('/api/auth/google-login', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  gmailLogin(data) {
    return this.request('/api/auth/gmail-login', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  // Top-Up
  getGames() { return this.request('/api/topups/games'); },
  getPackages(gameId) { return this.request(`/api/topups/games/${gameId}/packages`); },
  getFeaturedPackages() { return this.request('/api/topups/featured-packages'); },
  createOrder(data) {
    return this.request('/api/topups/orders', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  getOrder(orderId) { return this.request(`/api/topups/orders/${orderId}`); },

  // Wallet
  getWallet() { return this.request('/api/wallet'); },
  getTransactions() { return this.request('/api/wallet/transactions'); },
  depositWallet(amount, provider = 'esewa') {
    return this.request('/api/wallet/topups', {
      method: 'POST',
      body: JSON.stringify({ amount, provider, idempotencyKey: 'wal_dep_' + Date.now() })
    });
  },

  // Tournaments
  getTournaments(query = {}) {
    const params = new URLSearchParams(query).toString();
    return this.request('/api/tournaments' + (params ? '?' + params : ''));
  },
  getTournament(id) { return this.request(`/api/tournaments/${id}`); },
  registerTournament(id, data = {}) {
    return this.request(`/api/tournaments/${id}/register`, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  cancelRegistration(id) {
    return this.request(`/api/tournaments/${id}/cancel-registration`, {
      method: 'POST'
    });
  },
  getMyTournaments() { return this.request('/api/me/tournaments'); },
  getStandings(tournamentId) { return this.request(`/api/tournaments/${tournamentId}/standings`); },
  getLeaderboard() { return this.request('/api/leaderboard'); },
  getPlatformMetrics() { return this.request('/api/platform/metrics'); },

  // Matches & Room Secrets
  getMatches(tournamentId) { return this.request(`/api/tournaments/${tournamentId}/matches`); },
  getMatch(matchId) { return this.request(`/api/matches/${matchId}`); },
  submitMatchResult(matchId, data) {
    return this.request(`/api/matches/${matchId}/submit-result`, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  getAdminMatchSubmissions(matchId) {
    return this.request(`/api/admin/matches/${matchId}/submissions`);
  },

  // Disputes
  fileDispute(data) {
    return this.request('/api/disputes', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  getDisputes() { return this.request('/api/disputes'); },

  // Admin Dashboard
  getAdminOverview() { return this.request('/api/admin/overview'); },
  getAdminOrders() { return this.request('/api/admin/topup-orders'); },
  retryDelivery(orderId) {
    return this.request(`/api/admin/topup-orders/${orderId}/retry-delivery`, { method: 'POST' });
  },
  refundOrder(orderId, reason) {
    return this.request(`/api/admin/topup-orders/${orderId}/refund`, {
      method: 'POST',
      body: JSON.stringify({ reason })
    });
  },
  createPackage(data) {
    return this.request('/api/admin/topup-packages', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  createTournament(data) {
    return this.request('/api/admin/tournaments', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  cancelTournament(tournamentId, reason) {
    return this.request(`/api/admin/tournaments/${tournamentId}/cancel`, {
      method: 'POST',
      body: JSON.stringify({ reason })
    });
  },
  submitResults(matchId, results) {
    return this.request(`/api/admin/matches/${matchId}/results`, {
      method: 'POST',
      body: JSON.stringify({ results })
    });
  },
  approvePrize(payoutId) {
    return this.request(`/api/admin/prizes/${payoutId}/approve`, { method: 'POST' });
  },
  getPayouts() { return this.request('/api/admin/prizes'); },
  getAuditLogs() { return this.request('/api/admin/audit-logs'); },
  getAdminUsers() { return this.request('/api/admin/users'); },
  banUser(userId, status, reason) {
    return this.request(`/api/admin/users/${userId}/ban`, {
      method: 'PATCH',
      body: JSON.stringify({ status, reason })
    });
  },
  resolveDispute(disputeId, status, notes) {
    return this.request(`/api/admin/disputes/${disputeId}/resolve`, {
      method: 'PATCH',
      body: JSON.stringify({ status, notes })
    });
  },
  simulateWebhook(data) {
    return this.request('/api/admin/simulate-webhook', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  getPendingPayments() {
    return this.request('/api/admin/payments/pending');
  },
  verifyPayment(orderId) {
    return this.request(`/api/admin/payments/${orderId}/verify`, { method: 'POST' });
  },
  rejectPayment(orderId, reason) {
    return this.request(`/api/admin/payments/${orderId}/reject`, {
      method: 'POST',
      body: JSON.stringify({ reason })
    });
  },
  submitDepositProof(orderId, data) {
    return this.request(`/api/wallet/topups/${orderId}/proof`, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  withdrawWallet(amount, method = 'bank') {
    return this.request('/api/wallet/withdraw', {
      method: 'POST',
      body: JSON.stringify({ amount, method })
    });
  },

  // AI Subscriptions
  getAiTools() { return this.request('/api/ai/tools'); },
  getMyAiSubscriptions() { return this.request('/api/ai/my-subscriptions'); },
  subscribeAi(toolId, packageId, accountEmail, paymentMethod = 'wallet') {
    return this.request('/api/ai/subscribe', {
      method: 'POST',
      body: JSON.stringify({ toolId, packageId, accountEmail, paymentMethod })
    });
  },
  cancelAiSubscription(subId) {
    return this.request(`/api/ai/subscriptions/${subId}/cancel`, { method: 'POST' });
  },

  // Admin AI Subscription Management
  getAdminAiAnalytics() { return this.request('/api/admin/ai/analytics'); },
  getAdminAiSubscriptions() { return this.request('/api/admin/ai/subscriptions'); },
  activateAdminAiSubscription(subId, licenseKey) {
    return this.request(`/api/admin/ai/subscriptions/${subId}/activate`, {
      method: 'POST',
      body: JSON.stringify({ licenseKey })
    });
  },
  updateAdminAiSubscriptionStatus(subId, status) {
    return this.request(`/api/admin/ai/subscriptions/${subId}/status`, {
      method: 'POST',
      body: JSON.stringify({ status })
    });
  },
  renewAdminAiSubscription(subId, days = 30) {
    return this.request(`/api/admin/ai/subscriptions/${subId}/renew`, {
      method: 'POST',
      body: JSON.stringify({ days })
    });
  },
  getAdminAiKeys() { return this.request('/api/admin/ai/keys'); },
  addAdminAiKeys(data) {
    return this.request('/api/admin/ai/keys', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  deleteAdminAiKey(keyId) {
    return this.request(`/api/admin/ai/keys/${keyId}`, { method: 'DELETE' });
  },

  // Admin Games & Packages Catalog Management
  getAdminGames() { return this.request('/api/admin/games'); },
  createAdminGame(data) {
    return this.request('/api/admin/games', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  updateAdminGame(id, data) {
    return this.request(`/api/admin/games/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },
  deleteAdminGame(id) {
    return this.request(`/api/admin/games/${id}`, { method: 'DELETE' });
  },
  getAdminGamePackages(gameId) {
    return this.request(`/api/admin/games/${gameId}/packages`);
  },
  createAdminPackage(data) {
    return this.request('/api/admin/topup-packages', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  updateAdminPackage(id, data) {
    return this.request(`/api/admin/topup-packages/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },
  deleteAdminPackage(id) {
    return this.request(`/api/admin/topup-packages/${id}`, { method: 'DELETE' });
  },

  // Payment QR & Gateways
  getPaymentGateways() {
    return this.request('/api/payment-gateways');
  },
  getAdminPaymentGateways() {
    return this.request('/api/admin/payment-gateways');
  },
  createAdminPaymentGateway(data) {
    return this.request('/api/admin/payment-gateways', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  updateAdminPaymentGateway(id, data) {
    return this.request(`/api/admin/payment-gateways/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },
  deleteAdminPaymentGateway(id) {
    return this.request(`/api/admin/payment-gateways/${id}`, { method: 'DELETE' });
  },

  // Homepage Hero Banners & Promotions ("Top Things")
  getBanners() {
    return this.request('/api/banners');
  },
  getAdminBanners() {
    return this.request('/api/admin/banners');
  },
  createAdminBanner(data) {
    return this.request('/api/admin/banners', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  updateAdminBanner(id, data) {
    return this.request(`/api/admin/banners/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  },
  deleteAdminBanner(id) {
    return this.request(`/api/admin/banners/${id}`, { method: 'DELETE' });
  },

  // Live Support Chat
  getChatUnreadCount() {
    return this.request('/api/chat/unread-count');
  },
  getChatThreads() {
    return this.request('/api/chat/threads');
  },
  getChatThreadMessages(userId) {
    return this.request(`/api/chat/threads/${userId}`);
  },
  sendChatMessage(data) {
    return this.request('/api/chat/send', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  },

  // Media & File Upload Helper
  async uploadFile(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = async (e) => {
        try {
          const res = await this.request('/api/upload', {
            method: 'POST',
            body: JSON.stringify({
              data: e.target.result,
              filename: file.name,
              contentType: file.type
            })
          });
          resolve(res.url);
        } catch (err) {
          // If upload fails, fallback to data url
          resolve(e.target.result);
        }
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }
};

window.API = API;
