// Corporate RideShare Platform - Admin Dashboard JavaScript

class AdminDashboard {
    constructor() {
        this.authToken = null;
        this.currentUser = null;
        this.init();
    }

    async init() {
        await this.checkAuth();
        this.setupEventListeners();
        this.loadDashboardData();
    }

    async checkAuth() {
        // Check if user is already authenticated
        const token = localStorage.getItem('admin_token');
        if (token) {
            this.authToken = token;
            try {
                await this.loadCurrentUser();
                this.showAuthenticatedUI();
            } catch (error) {
                this.showLoginForm();
            }
        } else {
            this.showLoginForm();
        }
    }

    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const target = e.target.getAttribute('href').substring(1);
                this.showSection(target);
            });
        });

        // Login form
        const loginForm = document.getElementById('login-form');
        if (loginForm) {
            loginForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleLogin();
            });
        }

        // Logout
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', () => {
                this.handleLogout();
            });
        }
    }

    async handleLogin() {
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const companyId = document.getElementById('company-id').value;

        try {
            const response = await fetch('/api/v1/auth/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password, company_id: companyId }),
            });

            if (response.ok) {
                const data = await response.json();
                this.authToken = data.access_token;
                this.currentUser = data.user;
                
                localStorage.setItem('admin_token', this.authToken);
                this.showAuthenticatedUI();
                this.loadDashboardData();
            } else {
                const error = await response.json();
                this.showError(error.detail || 'Login failed');
            }
        } catch (error) {
            this.showError('Login failed: ' + error.message);
        }
    }

    async handleLogout() {
        this.authToken = null;
        this.currentUser = null;
        localStorage.removeItem('admin_token');
        this.showLoginForm();
    }

    async loadCurrentUser() {
        const response = await fetch('/api/v1/auth/me', {
            headers: {
                'Authorization': `Bearer ${this.authToken}`,
            },
        });

        if (!response.ok) {
            throw new Error('Failed to load user');
        }

        this.currentUser = await response.json();
    }

    async loadDashboardData() {
        if (!this.authToken) return;

        try {
            await Promise.all([
                this.loadCompanies(),
                this.loadUsers(),
                this.loadRides(),
                this.loadStats(),
            ]);
        } catch (error) {
            console.error('Failed to load dashboard data:', error);
        }
    }

    async loadCompanies() {
        try {
            const response = await fetch('/api/v1/companies/', {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                },
            });

            if (response.ok) {
                const companies = await response.json();
                this.updateCompaniesSection(companies);
            }
        } catch (error) {
            console.error('Failed to load companies:', error);
        }
    }

    async loadUsers() {
        try {
            const response = await fetch('/api/v1/users/', {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                },
            });

            if (response.ok) {
                const users = await response.json();
                this.updateUsersSection(users);
            }
        } catch (error) {
            console.error('Failed to load users:', error);
        }
    }

    async loadRides() {
        try {
            const response = await fetch('/api/v1/rides/', {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                },
            });

            if (response.ok) {
                const rides = await response.json();
                this.updateRidesSection(rides);
            }
        } catch (error) {
            console.error('Failed to load rides:', error);
        }
    }

    async loadStats() {
        try {
            const [companiesResponse, usersResponse, ridesResponse] = await Promise.all([
                fetch('/api/v1/companies/', {
                    headers: { 'Authorization': `Bearer ${this.authToken}` },
                }),
                fetch('/api/v1/users/', {
                    headers: { 'Authorization': `Bearer ${this.authToken}` },
                }),
                fetch('/api/v1/rides/', {
                    headers: { 'Authorization': `Bearer ${this.authToken}` },
                }),
            ]);

            const companies = await companiesResponse.json();
            const users = await usersResponse.json();
            const rides = await ridesResponse.json();

            this.updateStats(companies.length, users.length, rides.length);
        } catch (error) {
            console.error('Failed to load stats:', error);
        }
    }

    updateStats(companiesCount, usersCount, ridesCount) {
        const statsCards = document.querySelectorAll('.card-title');
        if (statsCards.length >= 4) {
            statsCards[0].textContent = companiesCount;
            statsCards[1].textContent = usersCount;
            statsCards[2].textContent = rides.filter(r => r.status === 'in_progress').length;
            statsCards[3].textContent = ridesCount;
        }
    }

    updateCompaniesSection(companies) {
        const companiesContent = document.getElementById('companies-content');
        if (!companiesContent) return;

        companiesContent.innerHTML = `
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5>Companies (${companies.length})</h5>
                <button class="btn btn-primary btn-sm" onclick="adminDashboard.showAddCompanyForm()">
                    <i class="fas fa-plus"></i> Add Company
                </button>
            </div>
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Address</th>
                            <th>Contact</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${companies.map(company => `
                            <tr>
                                <td>${company.name}</td>
                                <td>${company.address}</td>
                                <td>${company.contact_email}</td>
                                <td>
                                    <span class="badge ${company.is_active ? 'bg-success' : 'bg-danger'}">
                                        ${company.is_active ? 'Active' : 'Inactive'}
                                    </span>
                                </td>
                                <td>
                                    <button class="btn btn-sm btn-outline-primary" onclick="adminDashboard.editCompany('${company.id}')">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <button class="btn btn-sm btn-outline-danger" onclick="adminDashboard.deleteCompany('${company.id}')">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }

    updateUsersSection(users) {
        const usersContent = document.getElementById('users-content');
        if (!usersContent) return;

        usersContent.innerHTML = `
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5>Users (${users.length})</h5>
                <button class="btn btn-primary btn-sm" onclick="adminDashboard.showAddUserForm()">
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
                                <td>
                                    <span class="badge ${user.role === 'admin' ? 'bg-danger' : 'bg-primary'}">
                                        ${user.role}
                                    </span>
                                </td>
                                <td>
                                    <span class="badge ${user.is_active ? 'bg-success' : 'bg-danger'}">
                                        ${user.is_active ? 'Active' : 'Inactive'}
                                    </span>
                                </td>
                                <td>
                                    <button class="btn btn-sm btn-outline-primary" onclick="adminDashboard.editUser('${user.id}')">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <button class="btn btn-sm btn-outline-danger" onclick="adminDashboard.deleteUser('${user.id}')">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }

    updateRidesSection(rides) {
        const ridesContent = document.getElementById('rides-content');
        if (!ridesContent) return;

        ridesContent.innerHTML = `
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5>Rides (${rides.length})</h5>
            </div>
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>From</th>
                            <th>To</th>
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
                                <td>
                                    <span class="badge ${this.getStatusBadgeClass(ride.status)}">
                                        ${ride.status}
                                    </span>
                                </td>
                                <td>${new Date(ride.created_at).toLocaleDateString()}</td>
                                <td>
                                    <button class="btn btn-sm btn-outline-primary" onclick="adminDashboard.viewRide('${ride.id}')">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }

    getStatusBadgeClass(status) {
        const statusClasses = {
            'pending': 'bg-warning',
            'matched': 'bg-info',
            'in_progress': 'bg-primary',
            'completed': 'bg-success',
            'cancelled': 'bg-danger',
        };
        return statusClasses[status] || 'bg-secondary';
    }

    showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.section-content').forEach(section => {
            section.style.display = 'none';
        });

        // Show target section
        const targetSection = document.getElementById(`${sectionName}-content`);
        if (targetSection) {
            targetSection.style.display = 'block';
        }

        // Update navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        document.querySelector(`[href="#${sectionName}"]`).classList.add('active');
    }

    showLoginForm() {
        document.getElementById('login-section').style.display = 'block';
        document.getElementById('dashboard-section').style.display = 'none';
    }

    showAuthenticatedUI() {
        document.getElementById('login-section').style.display = 'none';
        document.getElementById('dashboard-section').style.display = 'block';
        
        // Update user info
        if (this.currentUser) {
            const userInfo = document.getElementById('user-info');
            if (userInfo) {
                userInfo.innerHTML = `
                    <span class="text-white">
                        <i class="fas fa-user"></i> ${this.currentUser.name}
                    </span>
                `;
            }
        }
    }

    showError(message) {
        // Create and show error toast
        const toast = document.createElement('div');
        toast.className = 'alert alert-danger alert-dismissible fade show position-fixed';
        toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999;';
        toast.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        document.body.appendChild(toast);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }

    showSuccess(message) {
        // Create and show success toast
        const toast = document.createElement('div');
        toast.className = 'alert alert-success alert-dismissible fade show position-fixed';
        toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999;';
        toast.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        document.body.appendChild(toast);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }

    // Placeholder methods for future implementation
    showAddCompanyForm() {
        this.showError('Add company functionality coming soon!');
    }

    editCompany(companyId) {
        this.showError('Edit company functionality coming soon!');
    }

    deleteCompany(companyId) {
        this.showError('Delete company functionality coming soon!');
    }

    showAddUserForm() {
        this.showError('Add user functionality coming soon!');
    }

    editUser(userId) {
        this.showError('Edit user functionality coming soon!');
    }

    deleteUser(userId) {
        this.showError('Delete user functionality coming soon!');
    }

    viewRide(rideId) {
        this.showError('View ride functionality coming soon!');
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.adminDashboard = new AdminDashboard();
});
