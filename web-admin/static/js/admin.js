// Admin Dashboard JavaScript
let currentUser = null;
let authToken = null;

document.addEventListener('DOMContentLoaded', function() {
    console.log('Admin dashboard loaded');
    
    // Check if user is logged in
    checkAuthStatus();
    
    // Setup event listeners
    setupEventListeners();
});

async function checkAuthStatus() {
    const token = localStorage.getItem('admin_token');
    if (token) {
        authToken = token;
        try {
            const response = await fetch('/api/v1/auth/me', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (response.ok) {
                currentUser = await response.json();
                loadDashboard();
            } else {
                showLoginForm();
            }
        } catch (error) {
            console.error('Auth check failed:', error);
            showLoginForm();
        }
    } else {
        showLoginForm();
    }
}

function showLoginForm() {
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
    
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
}

async function handleLogin(event) {
    event.preventDefault();
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const companyId = document.getElementById('companyId').value;
    
    try {
        const response = await fetch('/api/v1/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: email,
                password: password,
                company_id: companyId
            })
        });
        
        if (response.ok) {
            const data = await response.json();
            authToken = data.access_token;
            currentUser = data.user;
            localStorage.setItem('admin_token', authToken);
            loadDashboard();
        } else {
            const error = await response.json();
            alert('Login failed: ' + error.detail);
        }
    } catch (error) {
        console.error('Login error:', error);
        alert('Login failed. Please try again.');
    }
}

async function loadDashboard() {
    try {
        // Load dashboard data
        const [companies, users, rides] = await Promise.all([
            fetchData('/api/v1/companies/'),
            fetchData('/api/v1/users/'),
            fetchData('/api/v1/rides/')
        ]);
        
        updateDashboardStats(companies, users, rides);
        loadRecentActivity(rides);
        
    } catch (error) {
        console.error('Failed to load dashboard:', error);
    }
}

async function fetchData(endpoint) {
    try {
        const response = await fetch(endpoint, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        if (response.ok) {
            return await response.json();
        }
        return [];
    } catch (error) {
        console.error(`Failed to fetch ${endpoint}:`, error);
        return [];
    }
}

function updateDashboardStats(companies, users, rides) {
    // Update stats cards
    document.querySelector('.bg-primary .card-title').textContent = companies.length || 0;
    document.querySelector('.bg-success .card-title').textContent = users.filter(u => u.is_active).length || 0;
    document.querySelector('.bg-warning .card-title').textContent = rides.filter(r => r.status === 'in_progress').length || 0;
    document.querySelector('.bg-info .card-title').textContent = rides.length || 0;
}

function loadRecentActivity(rides) {
    const activityTable = document.getElementById('activity-table');
    if (!activityTable) return;
    
    if (rides.length === 0) {
        activityTable.innerHTML = '<tr><td colspan="5" class="text-center text-muted">No recent activity</td></tr>';
        return;
    }
    
    const recentRides = rides.slice(0, 10); // Show last 10 rides
    activityTable.innerHTML = recentRides.map(ride => `
        <tr>
            <td>${new Date(ride.created_at).toLocaleString()}</td>
            <td>${ride.status === 'completed' ? 'Ride completed' : 'Ride created'}</td>
            <td>${ride.rider_id}</td>
            <td>${ride.company_id}</td>
            <td><span class="badge bg-${getStatusColor(ride.status)}">${ride.status}</span></td>
        </tr>
    `).join('');
}

function getStatusColor(status) {
    switch (status) {
        case 'completed': return 'success';
        case 'in_progress': return 'warning';
        case 'matched': return 'info';
        case 'pending': return 'secondary';
        default: return 'secondary';
    }
}

function setupEventListeners() {
    // Sidebar navigation
    document.querySelectorAll('.sidebar .nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();

            // Remove active class from all links
            document.querySelectorAll('.sidebar .nav-link').forEach(l => l.classList.remove('active'));

            // Add active class to clicked link
            this.classList.add('active');

            // Load content based on href
            const section = this.getAttribute('href').substring(1);
            loadSection(section);
        });
    });
}

async function loadSection(section) {
    const mainContent = document.querySelector('main');
    
    switch (section) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'companies':
            await loadCompaniesSection();
            break;
        case 'users':
            await loadUsersSection();
            break;
        case 'rides':
            await loadRidesSection();
            break;
        case 'analytics':
            await loadAnalyticsSection();
            break;
        default:
            loadDashboard();
    }
}

async function loadCompaniesSection() {
    const mainContent = document.querySelector('main');
    mainContent.innerHTML = `
        <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
            <h1 class="h2">Companies</h1>
            <button class="btn btn-primary" onclick="showCreateCompanyModal()">Add Company</button>
        </div>
        <div id="companies-content">
            <div class="text-center">
                <div class="spinner-border" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
            </div>
        </div>
    `;
    
    try {
        const companies = await fetchData('/api/v1/companies/');
        displayCompanies(companies);
    } catch (error) {
        console.error('Failed to load companies:', error);
    }
}

function displayCompanies(companies) {
    const content = document.getElementById('companies-content');
    if (companies.length === 0) {
        content.innerHTML = '<p class="text-muted text-center">No companies found</p>';
        return;
    }
    
    content.innerHTML = `
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
                            <td><span class="badge bg-${company.is_active ? 'success' : 'danger'}">${company.is_active ? 'Active' : 'Inactive'}</span></td>
                            <td>
                                <button class="btn btn-sm btn-outline-primary" onclick="editCompany('${company.id}')">Edit</button>
                                <button class="btn btn-sm btn-outline-danger" onclick="deleteCompany('${company.id}')">Delete</button>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// Add more section loading functions as needed...
async function loadUsersSection() {
    // Similar to companies section
    const mainContent = document.querySelector('main');
    mainContent.innerHTML = `
        <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
            <h1 class="h2">Users</h1>
        </div>
        <div class="text-center">
            <p>Users management coming soon...</p>
        </div>
    `;
}

async function loadRidesSection() {
    // Similar to companies section
    const mainContent = document.querySelector('main');
    mainContent.innerHTML = `
        <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
            <h1 class="h2">Rides</h1>
        </div>
        <div class="text-center">
            <p>Rides management coming soon...</p>
        </div>
    `;
}

async function loadAnalyticsSection() {
    // Similar to companies section
    const mainContent = document.querySelector('main');
    mainContent.innerHTML = `
        <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
            <h1 class="h2">Analytics</h1>
        </div>
        <div class="text-center">
            <p>Analytics dashboard coming soon...</p>
        </div>
    `;
}
