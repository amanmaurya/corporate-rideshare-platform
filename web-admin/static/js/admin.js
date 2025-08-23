// Corporate RideShare Admin Dashboard JavaScript

class AdminDashboard {
    constructor() {
        this.apiBaseUrl = '/api/v1';
        this.currentUser = null;
        this.init();
    }

    async init() {
        await this.checkAuth();
        this.setupEventListeners();
        this.loadDashboardData();
        this.startAutoRefresh();
    }

    async checkAuth() {
        const token = localStorage.getItem('admin_token');
        if (!token) {
            this.showLoginForm();
            return;
        }

        try {
            const response = await fetch(`${this.apiBaseUrl}/auth/me`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                this.currentUser = await response.json();
                this.hideLoginForm();
                this.updateUserInfo();
            } else {
                localStorage.removeItem('admin_token');
                this.showLoginForm();
            }
        } catch (error) {
            console.error('Auth check failed:', error);
            this.showLoginForm();
        }
    }

    showLoginForm() {
        const mainContent = document.querySelector('main');
        mainContent.innerHTML = `
            <div class="d-flex justify-content-center align-items-center" style="height: 80vh;">
                <div class="card" style="width: 400px;">
                    <div class="card-header text-center">
                        <h4>Admin Login</h4>
                    </div>
                    <div class="card-body">
                        <form id="loginForm">
                            <div class="mb-3">
                                <label for="email" class="form-label">Email</label>
                                <input type="email" class="form-control" id="email" required>
                            </div>
                            <div class="mb-3">
                                <label for="password" class="form-label">Password</label>
                                <input type="password" class="form-control" id="password" required>
                            </div>
                            <div class="mb-3">
                                <label for="companyId" class="form-label">Company ID</label>
                                <input type="text" class="form-control" id="companyId" value="company-1" required>
                            </div>
                            <button type="submit" class="btn btn-primary w-100">Login</button>
                        </form>
                    </div>
                </div>
            </div>
        `;

        document.getElementById('loginForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleLogin();
        });
    }

    hideLoginForm() {
        this.loadMainDashboard();
    }

    async handleLogin() {
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const companyId = document.getElementById('companyId').value;

        try {
            const response = await fetch(`${this.apiBaseUrl}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ email, password, company_id: companyId })
            });

            if (response.ok) {
                const data = await response.json();
                localStorage.setItem('admin_token', data.access_token);
                this.currentUser = data.user;
                this.hideLoginForm();
                this.updateUserInfo();
            } else {
                const error = await response.json();
                this.showAlert('Login failed: ' + error.detail, 'danger');
            }
        } catch (error) {
            console.error('Login failed:', error);
            this.showAlert('Login failed. Please try again.', 'danger');
        }
    }

    loadMainDashboard() {
        const mainContent = document.querySelector('main');
        mainContent.innerHTML = `
            <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                <h1 class="h2">Dashboard</h1>
                <div class="btn-toolbar mb-2 mb-md-0">
                    <div class="btn-group me-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary" onclick="adminDashboard.exportData()">Export</button>
                        <button type="button" class="btn btn-sm btn-outline-secondary" onclick="adminDashboard.refreshData()">Refresh</button>
                    </div>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="row mb-4" id="statsCards">
                <!-- Stats will be loaded here -->
            </div>

            <!-- Recent Activity -->
            <div class="row mt-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h5>Recent Activity</h5>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-striped">
                                    <thead>
                                        <tr>
                                            <th>Time</th>
                                            <th>Activity</th>
                                            <th>User</th>
                                            <th>Company</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody id="activity-table">
                                        <!-- Activity data will be loaded here -->
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Charts Section -->
            <div class="row mt-4">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5>Ride Statistics</h5>
                        </div>
                        <div class="card-body">
                            <canvas id="rideChart" width="400" height="200"></canvas>
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5>User Activity</h5>
                        </div>
                        <div class="card-body">
                            <canvas id="userChart" width="400" height="200"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    updateUserInfo() {
        if (this.currentUser) {
            const userInfo = document.querySelector('.text-primary');
            if (userInfo) {
                userInfo.textContent = `Welcome, ${this.currentUser.name}`;
            }
        }
    }

    setupEventListeners() {
        // Navigation event listeners
        document.addEventListener('click', (e) => {
            if (e.target.matches('.nav-link')) {
                e.preventDefault();
                const target = e.target.getAttribute('href').substring(1);
                this.navigateToSection(target);
            }
        });
    }

    navigateToSection(section) {
        // Remove active class from all nav links
        document.querySelectorAll('.nav-link').forEach(link => link.classList.remove('active'));
        
        // Add active class to clicked link
        document.querySelector(`[href="#${section}"]`).classList.add('active');

        // Load section content
        switch (section) {
            case 'dashboard':
                this.loadDashboardData();
                break;
            case 'companies':
                this.loadCompaniesData();
                break;
            case 'users':
                this.loadUsersData();
                break;
            case 'rides':
                this.loadRidesData();
                break;
            case 'analytics':
                this.loadAnalyticsData();
                break;
        }
    }

    async loadDashboardData() {
        try {
            const [companies, users, rides, payments] = await Promise.all([
                this.fetchData('companies'),
                this.fetchData('users'),
                this.fetchData('rides'),
                this.fetchData('payments/company/summary')
            ]);

            this.updateStatsCards(companies, users, rides, payments);
            this.updateActivityTable(rides);
            this.updateCharts(rides, users);
        } catch (error) {
            console.error('Failed to load dashboard data:', error);
            this.showAlert('Failed to load dashboard data', 'danger');
        }
    }

    async fetchData(endpoint) {
        const token = localStorage.getItem('admin_token');
        const response = await fetch(`${this.apiBaseUrl}/${endpoint}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            return await response.json();
        } else {
            throw new Error(`Failed to fetch ${endpoint}`);
        }
    }

    updateStatsCards(companies, users, rides, payments) {
        const statsCards = document.getElementById('statsCards');
        if (!statsCards) return;

        statsCards.innerHTML = `
            <div class="col-md-3">
                <div class="card text-white bg-primary">
                    <div class="card-body">
                        <div class="d-flex justify-content-between">
                            <div>
                                <h4 class="card-title">${companies.length || 0}</h4>
                                <p class="card-text">Total Companies</p>
                            </div>
                            <div class="align-self-center">
                                <i class="fas fa-building fa-2x"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-success">
                    <div class="card-body">
                        <div class="d-flex justify-content-between">
                            <div>
                                <h4 class="card-title">${users.length || 0}</h4>
                                <p class="card-text">Active Users</p>
                            </div>
                            <div class="align-self-center">
                                <i class="fas fa-users fa-2x"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-warning">
                    <div class="card-body">
                        <div class="d-flex justify-content-between">
                            <div>
                                <h4 class="card-title">${rides.filter(r => r.status === 'in_progress').length || 0}</h4>
                                <p class="card-text">Active Rides</p>
                            </div>
                            <div class="align-self-center">
                                <i class="fas fa-car fa-2x"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-info">
                    <div class="card-body">
                        <div class="d-flex justify-content-between">
                            <div>
                                <h4 class="card-title">${rides.length || 0}</h4>
                                <p class="card-text">Total Rides</p>
                            </div>
                            <div class="align-self-center">
                                <i class="fas fa-chart-line fa-2x"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    updateActivityTable(rides) {
        const activityTable = document.getElementById('activity-table');
        if (!activityTable) return;

        const recentRides = rides.slice(0, 10);
        
        if (recentRides.length === 0) {
            activityTable.innerHTML = '<tr><td colspan="5" class="text-center text-muted">No recent activity</td></tr>';
            return;
        }

        activityTable.innerHTML = recentRides.map(ride => `
            <tr>
                <td>${new Date(ride.created_at).toLocaleString()}</td>
                <td>Ride ${ride.status} from ${ride.pickup_location} to ${ride.destination}</td>
                <td>${ride.rider_id}</td>
                <td>${ride.company_id}</td>
                <td><span class="badge bg-${this.getStatusColor(ride.status)}">${ride.status}</span></td>
            </tr>
        `).join('');
    }

    getStatusColor(status) {
        const colors = {
            'pending': 'warning',
            'matched': 'info',
            'in_progress': 'primary',
            'completed': 'success',
            'cancelled': 'danger'
        };
        return colors[status] || 'secondary';
    }

    updateCharts(rides, users) {
        this.createRideChart(rides);
        this.createUserChart(users);
    }

    createRideChart(rides) {
        const ctx = document.getElementById('rideChart');
        if (!ctx) return;

        const statusCounts = rides.reduce((acc, ride) => {
            acc[ride.status] = (acc[ride.status] || 0) + 1;
            return acc;
        }, {});

        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: Object.keys(statusCounts),
                datasets: [{
                    data: Object.values(statusCounts),
                    backgroundColor: [
                        '#FF6384',
                        '#36A2EB',
                        '#FFCE56',
                        '#4BC0C0',
                        '#9966FF'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    }

    createUserChart(users) {
        const ctx = document.getElementById('userChart');
        if (!ctx) return;

        const departmentCounts = users.reduce((acc, user) => {
            acc[user.department] = (acc[user.department] || 0) + 1;
            return acc;
        }, {});

        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: Object.keys(departmentCounts),
                datasets: [{
                    label: 'Users per Department',
                    data: Object.values(departmentCounts),
                    backgroundColor: '#36A2EB'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    async loadCompaniesData() {
        try {
            const companies = await this.fetchData('companies');
            this.displayCompaniesTable(companies);
        } catch (error) {
            console.error('Failed to load companies:', error);
            this.showAlert('Failed to load companies data', 'danger');
        }
    }

    async loadUsersData() {
        try {
            const users = await this.fetchData('users');
            this.displayUsersTable(users);
        } catch (error) {
            console.error('Failed to load users:', error);
            this.showAlert('Failed to load users data', 'danger');
        }
    }

    async loadRidesData() {
        try {
            const rides = await this.fetchData('rides');
            this.displayRidesTable(rides);
        } catch (error) {
            console.error('Failed to load rides:', error);
            this.showAlert('Failed to load rides data', 'danger');
        }
    }

    async loadAnalyticsData() {
        try {
            const [rides, payments] = await Promise.all([
                this.fetchData('rides'),
                this.fetchData('payments/company/summary')
            ]);
            this.displayAnalytics(rides, payments);
        } catch (error) {
            console.error('Failed to load analytics:', error);
            this.showAlert('Failed to load analytics data', 'danger');
        }
    }

    displayCompaniesTable(companies) {
        const mainContent = document.querySelector('main');
        mainContent.innerHTML = `
            <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                <h1 class="h2">Companies Management</h1>
                <button class="btn btn-primary" onclick="adminDashboard.showAddCompanyModal()">
                    <i class="fas fa-plus"></i> Add Company
                </button>
            </div>
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Contact Email</th>
                            <th>Contact Phone</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${companies.map(company => `
                            <tr>
                                <td>${company.name}</td>
                                <td>${company.contact_email}</td>
                                <td>${company.contact_phone}</td>
                                <td><span class="badge bg-${company.is_active ? 'success' : 'danger'}">${company.is_active ? 'Active' : 'Inactive'}</span></td>
                                <td>
                                    <button class="btn btn-sm btn-outline-primary" onclick="adminDashboard.editCompany('${company.id}')">Edit</button>
                                    <button class="btn btn-sm btn-outline-danger" onclick="adminDashboard.deleteCompany('${company.id}')">Delete</button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }

    displayUsersTable(users) {
        const mainContent = document.querySelector('main');
        mainContent.innerHTML = `
            <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                <h1 class="h2">Users Management</h1>
                <button class="btn btn-primary" onclick="adminDashboard.showAddUserModal()">
                    <i class="fas fa-plus"></i> Add User
                </button>
            </div>
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Department</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${users.map(user => `
                            <tr>
                                <td>${user.name}</td>
                                <td>${user.email}</td>
                                <td>${user.department}</td>
                                <td>${user.role}</td>
                                <td><span class="badge bg-${user.is_active ? 'success' : 'danger'}">${user.is_active ? 'Active' : 'Inactive'}</span></td>
                                <td>
                                    <button class="btn btn-sm btn-outline-primary" onclick="adminDashboard.editUser('${user.id}')">Edit</button>
                                    <button class="btn btn-sm btn-outline-danger" onclick="adminDashboard.deleteUser('${user.id}')">Delete</button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }

    displayRidesTable(rides) {
        const mainContent = document.querySelector('main');
        mainContent.innerHTML = `
            <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                <h1 class="h2">Rides Management</h1>
            </div>
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Pickup</th>
                            <th>Destination</th>
                            <th>Rider</th>
                            <th>Status</th>
                            <th>Created</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${rides.map(ride => `
                            <tr>
                                <td>${ride.pickup_location}</td>
                                <td>${ride.destination}</td>
                                <td>${ride.rider_id}</td>
                                <td><span class="badge bg-${this.getStatusColor(ride.status)}">${ride.status}</span></td>
                                <td>${new Date(ride.created_at).toLocaleDateString()}</td>
                                <td>
                                    <button class="btn btn-sm btn-outline-info" onclick="adminDashboard.viewRideDetails('${ride.id}')">View</button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }

    displayAnalytics(rides, payments) {
        const mainContent = document.querySelector('main');
        mainContent.innerHTML = `
            <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                <h1 class="h2">Analytics Dashboard</h1>
            </div>
            
            <div class="row">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5>Ride Statistics</h5>
                        </div>
                        <div class="card-body">
                            <canvas id="analyticsRideChart" width="400" height="200"></canvas>
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5>Payment Summary</h5>
                        </div>
                        <div class="card-body">
                            <div class="row text-center">
                                <div class="col-6">
                                    <h3 class="text-primary">$${payments.total_amount || 0}</h3>
                                    <p>Total Revenue</p>
                                </div>
                                <div class="col-6">
                                    <h3 class="text-success">${payments.total_payments || 0}</h3>
                                    <p>Total Payments</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Create analytics chart
        this.createAnalyticsChart(rides);
    }

    createAnalyticsChart(rides) {
        const ctx = document.getElementById('analyticsRideChart');
        if (!ctx) return;

        const monthlyData = this.groupRidesByMonth(rides);
        
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: Object.keys(monthlyData),
                datasets: [{
                    label: 'Rides per Month',
                    data: Object.values(monthlyData),
                    borderColor: '#36A2EB',
                    backgroundColor: 'rgba(54, 162, 235, 0.1)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    groupRidesByMonth(rides) {
        const monthlyData = {};
        rides.forEach(ride => {
            const date = new Date(ride.created_at);
            const monthYear = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
            monthlyData[monthYear] = (monthlyData[monthYear] || 0) + 1;
        });
        return monthlyData;
    }

    showAlert(message, type = 'info') {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
        alertDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        const container = document.querySelector('.container-fluid');
        container.insertBefore(alertDiv, container.firstChild);
        
        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, 5000);
    }

    refreshData() {
        this.loadDashboardData();
        this.showAlert('Data refreshed successfully', 'success');
    }

    exportData() {
        // TODO: Implement data export functionality
        this.showAlert('Export functionality coming soon!', 'info');
    }

    startAutoRefresh() {
        // Refresh data every 30 seconds
        setInterval(() => {
            if (document.querySelector('#statsCards')) {
                this.loadDashboardData();
            }
        }, 30000);
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.adminDashboard = new AdminDashboard();
});
