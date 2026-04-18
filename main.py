from flask import Flask, render_template, request, jsonify
import json
import os

app = Flask(__name__)

# Путь к файлу для хранения заявок
CONTACTS_FILE = 'contacts.json'
LOCATIONS_FILE = 'locations.json'


def load_json_file(filename, default=None):
    """Загрузка данных из JSON файла."""
    if default is None:
        default = []
    if os.path.exists(filename):
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return default
    return default


def save_json_file(filename, data):
    """Сохранение данных в JSON файл."""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


@app.route('/')
def index():
    """Главная страница."""
    return render_template('index.html')


@app.route('/admin')
def admin():
    """Админ панель."""
    return render_template('admin.html')


@app.route('/api/contact', methods=['POST'])
def contact_form():
    """Обработка формы контактов."""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Нет данных'}), 400
        
        # Проверка обязательных полей
        required_fields = ['name', 'phone', 'email', 'car']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'Отсутствует поле: {field}'}), 400
        
        # Загрузка существующих контактов
        contacts = load_json_file(CONTACTS_FILE, [])
        
        # Добавление новой заявки
        contact_entry = {
            'name': data['name'],
            'phone': data['phone'],
            'email': data['email'],
            'car': data['car'],
            'message': data.get('message', ''),
            'timestamp': data.get('timestamp', '')
        }
        contacts.append(contact_entry)
        
        # Сохранение в файл
        save_json_file(CONTACTS_FILE, contacts)
        
        return jsonify({
            'success': True,
            'message': 'Заявка успешно отправлена!',
            'contact_id': len(contacts)
        })
        
    except Exception as e:
        return jsonify({'error': f'Ошибка сервера: {str(e)}'}), 500


@app.route('/api/locations', methods=['GET'])
def get_locations():
    """Получение всех геолокаций."""
    locations = load_json_file(LOCATIONS_FILE, [])
    return jsonify({'locations': locations})


@app.route('/api/location', methods=['POST'])
def save_location():
    """Сохранение геолокации от клиента."""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Нет данных'}), 400
        
        # Проверка обязательных полей
        if 'lat' not in data or 'lng' not in data:
            return jsonify({'error': 'Отсутствуют координаты'}), 400
        
        # Загрузка существующих локаций
        locations = load_json_file(LOCATIONS_FILE, [])
        
        # Добавление новой локации
        location_entry = {
            'lat': data['lat'],
            'lng': data['lng'],
            'locationUrl': data.get('locationUrl', ''),
            'timestamp': data.get('timestamp', ''),
            'user_agent': data.get('user_agent', '')
        }
        locations.append(location_entry)
        
        # Сохранение в файл
        save_json_file(LOCATIONS_FILE, locations)
        
        return jsonify({
            'success': True,
            'message': 'Геолокация сохранена',
            'location_id': len(locations)
        })
        
    except Exception as e:
        return jsonify({'error': f'Ошибка сервера: {str(e)}'}), 500


@app.route('/api/contacts', methods=['GET'])
def get_contacts():
    """Получение всех контактов."""
    contacts = load_json_file(CONTACTS_FILE, [])
    return jsonify({'contacts': contacts})


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Получение статистики."""
    contacts = load_json_file(CONTACTS_FILE, [])
    locations = load_json_file(LOCATIONS_FILE, [])
    
    return jsonify({
        'total_contacts': len(contacts),
        'total_locations': len(locations)
    })


if __name__ == '__main__':
    print('Запуск сервера AutoShop...')
    print('Сервер доступен по адресу: http://localhost:5000')
    print('Админ панель (статистика): http://localhost:5000/api/stats')
    app.run(debug=False, host='0.0.0.0', port=5000)
