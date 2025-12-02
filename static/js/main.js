// Main JavaScript file for Student Portal System

// Auto-hide flash messages after 5 seconds
document.addEventListener('DOMContentLoaded', function () {
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.transition = 'opacity 0.5s';
            alert.style.opacity = '0';
            setTimeout(() => {
                alert.remove();
            }, 500);
        }, 5000);
    });

    const userMenu = document.querySelector('[data-user-menu]');
    const userToggle = document.querySelector('[data-user-toggle]');
    if (userMenu && userToggle) {
        userToggle.addEventListener('click', function (event) {
            event.stopPropagation();
            userMenu.classList.toggle('open');
        });

        userMenu.addEventListener('click', function (event) {
            event.stopPropagation();
        });

        document.addEventListener('click', function () {
            userMenu.classList.remove('open');
        });
    }

    // Sidebar toggle (hamburger drawer)
    const sidebarToggle = document.querySelector('[data-sidebar-toggle]');
    const sidebarOverlay = document.querySelector('[data-sidebar-overlay]');
    const sidebarHoverZone = document.querySelector('[data-sidebar-hover]');
    const body = document.body;

    function toggleSidebar(open) {
        const shouldOpen = typeof open === 'boolean' ? open : !body.classList.contains('sidebar-open');
        if (shouldOpen) {
            body.classList.add('sidebar-open');
        } else {
            body.classList.remove('sidebar-open');
        }
    }

    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', function (e) {
            e.stopPropagation();
            toggleSidebar();
        });
    }

    if (sidebarOverlay) {
        sidebarOverlay.addEventListener('click', function () {
            toggleSidebar(false);
        });
    }

    // Desktop: auto-open on hover near left edge
    if (sidebarHoverZone) {
        sidebarHoverZone.addEventListener('mouseenter', function () {
            if (window.innerWidth >= 992) {
                toggleSidebar(true);
            }
        });
    }

    // Desktop: open sidebar by default on load
    if (window.innerWidth >= 992) {
        body.classList.add('sidebar-open');
    }

    // Close sidebar on ESC key
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            toggleSidebar(false);
        }
    });

    // SweetAlert-style popup based on first flash message (if any)
    const popupRoot = document.getElementById('popupAlert');
    if (popupRoot) {
        const popupIcon = popupRoot.querySelector('[data-popup-icon]');
        const popupTitle = popupRoot.querySelector('[data-popup-title]');
        const popupMessage = popupRoot.querySelector('[data-popup-message]');
        const popupOk = popupRoot.querySelector('[data-popup-ok]');
        const popupClose = popupRoot.querySelector('[data-popup-close]');

        function hidePopup() {
            popupRoot.classList.remove('active');
            popupRoot.setAttribute('aria-hidden', 'true');
        }

        if (popupOk) popupOk.addEventListener('click', hidePopup);
        if (popupClose) popupClose.addEventListener('click', hidePopup);

        const firstAlert = document.querySelector('.flash-messages .alert');
        if (firstAlert && popupIcon && popupTitle && popupMessage) {
            const category = Array.from(firstAlert.classList)
                .find(c => c.startsWith('alert-')) || 'alert-info';
            const text = firstAlert.textContent.replace(/×\s*$/, '').trim();

            // Map category to icon and title
            let iconClass = 'success';
            let titleText = 'Success';
            if (category.includes('danger')) {
                iconClass = 'danger';
                titleText = 'Error';
            } else if (category.includes('info')) {
                iconClass = 'info';
                titleText = 'Information';
            }

            popupIcon.className = 'popup-icon ' + iconClass;
            popupIcon.innerHTML = iconClass === 'success'
                ? '<i class="fas fa-check"></i>'
                : iconClass === 'danger'
                    ? '<i class="fas fa-times"></i>'
                    : '<i class="fas fa-info"></i>';
            popupTitle.textContent = titleText;
            popupMessage.textContent = text;

            popupRoot.classList.add('active');
            popupRoot.setAttribute('aria-hidden', 'false');
        }
    }
});

// Form validation
function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return false;

    const inputs = form.querySelectorAll('input[required], textarea[required], select[required]');
    let isValid = true;

    inputs.forEach(input => {
        if (!input.value.trim()) {
            isValid = false;
            input.style.borderColor = '#ef4444';
        } else {
            input.style.borderColor = '';
        }
    });

    return isValid;
}

// Confirm delete actions
function confirmAction(message, callback) {
    if (confirm(message)) {
        callback();
    }
}

// Smooth scroll
function smoothScrollTo(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
    }
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// Format time
function formatTime(timeString) {
    if (!timeString) return '';
    const [hours, minutes] = timeString.split(':');
    const hour = parseInt(hours);
    const ampm = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour % 12 || 12;
    return `${displayHour}:${minutes} ${ampm}`;
}

// Loading state for buttons
function setLoadingState(button, isLoading) {
    if (isLoading) {
        button.disabled = true;
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
    }
}

// Show notification
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `alert alert-${type}`;
    notification.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'danger' ? 'exclamation-circle' : 'info-circle'}"></i>
        ${message}
        <button class="close-btn" onclick="this.parentElement.remove()">&times;</button>
    `;

    const container = document.querySelector('.flash-messages') || document.querySelector('.main-content');
    if (container) {
        container.insertBefore(notification, container.firstChild);

        setTimeout(() => {
            notification.style.transition = 'opacity 0.5s';
            notification.style.opacity = '0';
            setTimeout(() => notification.remove(), 500);
        }, 5000);
    }
}

// Table search functionality
function setupTableSearch(inputId, tableId) {
    const searchInput = document.getElementById(inputId);
    const table = document.getElementById(tableId);

    if (!searchInput || !table) return;

    searchInput.addEventListener('keyup', function () {
        const filter = this.value.toLowerCase();
        const rows = table.querySelectorAll('tbody tr');

        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = text.includes(filter) ? '' : 'none';
        });
    });
}

// Export to CSV (for future use)
function exportToCSV(tableId, filename) {
    const table = document.getElementById(tableId);
    if (!table) return;

    let csv = [];
    const rows = table.querySelectorAll('tr');

    rows.forEach(row => {
        const cols = row.querySelectorAll('td, th');
        const rowData = [];
        cols.forEach(col => {
            rowData.push('"' + col.textContent.replace(/"/g, '""') + '"');
        });
        csv.push(rowData.join(','));
    });

    const csvContent = csv.join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
}

