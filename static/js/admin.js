// Admin panel JavaScript
document.addEventListener('DOMContentLoaded', function() {
    const loginOverlay = document.getElementById('login-overlay');
    const loginForm = document.getElementById('login-form');
    const passwordInput = document.getElementById('password');
    const loginError = document.getElementById('login-error');
    const adminContent = document.getElementById('admin-content');
    const logoutBtn = document.getElementById('logout-btn');
    
    const contactsTableBody = document.getElementById('contacts-table-body');
    const locationsTableBody = document.getElementById('locations-table-body');
    const totalContactsEl = document.getElementById('total-contacts');
    const totalLocationsEl = document.getElementById('total-locations');
    
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    
    // Пароль для входа
    const ADMIN_PASSWORD = 'admin'; // Можно заменить на свой
    
    // Проверка сессии при загрузке
    checkSession();
    
    // Функция проверки сессии
    function checkSession() {
        const session = sessionStorage.getItem('adminSession');
        if (session === 'authenticated') {
            showAdminContent();
        } else {
            showLogin();
        }
    }
    
    // Функция показа формы входа
    function showLogin() {
        loginOverlay.classList.remove('hidden');
        adminContent.classList.remove('visible');
    }
    
    // Функция показа админ контента
    function showAdminContent() {
        loginOverlay.classList.add('hidden');
        adminContent.classList.add('visible');
        loadData();
    }
    
    // Обработка формы входа
    loginForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        const password = passwordInput.value.trim();
        
        if (password === ADMIN_PASSWORD) {
            sessionStorage.setItem('adminSession', 'authenticated');
            showAdminContent();
            passwordInput.value = '';
        } else {
            loginError.textContent = 'Неверный пароль!';
            passwordInput.classList.add('error');
            setTimeout(() => {
                passwordInput.classList.remove('error');
                loginError.textContent = '';
            }, 3000);
        }
    });
    
    // Выход
    logoutBtn.addEventListener('click', function() {
        sessionStorage.removeItem('adminSession');
        showLogin();
    });
    
    // Переключение вкладок
    tabBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            // Удаление активного класса у всех кнопок и контентов
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            
            // Добавление активного класса текущей кнопке и контенту
            btn.classList.add('active');
            const tabId = btn.dataset.tab + '-content';
            document.getElementById(tabId).classList.add('active');
        });
    });
    
    // Загрузка данных
    async function loadData() {
        try {
            // Загрузка контактов
            const contactsResponse = await fetch('/api/contacts');
            const contactsData = await contactsResponse.json();
            
            // Загрузка локаций
            const locationsResponse = await fetch('/api/locations');
            const locationsData = await locationsResponse.json();
            
            // Обновление статистики
            totalContactsEl.textContent = contactsData.contacts.length;
            totalLocationsEl.textContent = locationsData.locations.length;
            
            // Очистка таблиц
            contactsTableBody.innerHTML = '';
            locationsTableBody.innerHTML = '';
            
            // Заполнение таблицы контактов
            if (contactsData.contacts.length > 0) {
                contactsData.contacts.forEach((contact, index) => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td>${index + 1}</td>
                        <td>${escapeHtml(contact.name)}</td>
                        <td>${escapeHtml(contact.phone)}</td>
                        <td>${escapeHtml(contact.email)}</td>
                        <td>${escapeHtml(contact.car)}</td>
                        <td>${escapeHtml(contact.message) || '-'}</td>
                        <td>${formatTimestamp(contact.timestamp)}</td>
                    `;
                    contactsTableBody.appendChild(row);
                });
            } else {
                contactsTableBody.innerHTML = '<tr><td colspan="7" style="text-align: center;">Нет заявок</td></tr>';
            }
            
            // Заполнение таблицы локаций
            if (locationsData.locations.length > 0) {
                locationsData.locations.forEach((location, index) => {
                    const row = document.createElement('tr');
                    const locationUrl = location.locationUrl || `https://www.google.com/maps?q=${location.lat},${location.lng}`;
                    row.innerHTML = `
                        <td>${index + 1}</td>
                        <td>${location.lat.toFixed(6)}</td>
                        <td>${location.lng.toFixed(6)}</td>
                        <td><a href="${locationUrl}" target="_blank" class="location-link">Открыть</a></td>
                        <td>${formatTimestamp(location.timestamp)}</td>
                        <td>${escapeHtml(location.user_agent) || '-'}</td>
                    `;
                    locationsTableBody.appendChild(row);
                });
            } else {
                locationsTableBody.innerHTML = '<tr><td colspan="6" style="text-align: center;">Нет геолокаций</td></tr>';
            }
            
        } catch (error) {
            console.error('Ошибка загрузки данных:', error);
        }
    }
    
    // Функция экранирования HTML
    function escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    
    // Функция форматирования времени
    function formatTimestamp(timestamp) {
        if (!timestamp) return '-';
        const date = new Date(timestamp);
        return date.toLocaleString('ru-RU', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    }
});
