#!/usr/bin/env bash

# ============================================================
#  launch.sh — venv + Python app + ngrok launcher
#  Використання: ./launch.sh [опції]
# ============================================================

set -euo pipefail

# ---------- Налаштування (змініть під себе) ----------
VENV_DIR="${VENV_DIR:-.venv}"
APP_FILE="${APP_FILE:-main.py}"
APP_PORT="${APP_PORT:-5000}"
NGROK_REGION="${NGROK_REGION:-eu}"
LOG_FILE="/tmp/launch_$$.log"
NGROK_LOG="/tmp/ngrok_$$.log"
# -----------------------------------------------------

# ─── Кольори ───────────────────────────────────────
R='\033[0;31m'  G='\033[0;32m'  Y='\033[0;33m'
B='\033[0;34m'  M='\033[0;35m'  C='\033[0;36m'
W='\033[1;37m'  DIM='\033[2m'   BOLD='\033[1m'
RESET='\033[0m'

# ─── Розміри термінала ──────────────────────────────
TW=$(tput cols 2>/dev/null || echo 72)
[ "$TW" -gt 80 ] && TW=80

# ─── Утиліти малювання ─────────────────────────────
line() {
    local char="${1:─}" len="${2:-$TW}"
    printf '%*s' "$len" '' | tr ' ' "$char"
}

center() {
    local text="$1" color="${2:-$RESET}"
    local visible
    visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( (TW - ${#visible}) / 2 ))
    printf "%${pad}s${color}%s${RESET}\n" '' "$text"
}

box_line() {
    local label="$1" value="${2:-}" color="${3:-$C}"
    printf "  ${DIM}│${RESET}  ${color}%-20s${RESET}  ${W}%s${RESET}\n" "$label" "$value"
}

separator() {
    echo -e "  ${DIM}├$(line ─ $((TW-4)))┤${RESET}"
}

top_border() {
    echo -e "  ${DIM}┌$(line ─ $((TW-4)))┐${RESET}"
}

bot_border() {
    echo -e "  ${DIM}└$(line ─ $((TW-4)))┘${RESET}"
}

# ─── Спіннер ───────────────────────────────────────
SPIN_PID=""
spin_start() {
    local msg="$1"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    (
        i=0
        while true; do
            printf "\r  ${C}${frames[$((i % 10))]}${RESET}  %s  " "$msg"
            sleep 0.08
            ((i++))
        done
    ) &
    SPIN_PID=$!
    disown "$SPIN_PID" 2>/dev/null || true
}

spin_stop() {
    if [[ -n "$SPIN_PID" ]]; then
        kill "$SPIN_PID" 2>/dev/null || true
        SPIN_PID=""
        printf "\r%${TW}s\r" ''
    fi
}

ok()   { spin_stop; echo -e "  ${G}✔${RESET}  $1"; }
fail() { spin_stop; echo -e "  ${R}✘${RESET}  $1"; }
info() { echo -e "  ${B}ℹ${RESET}  $1"; }
warn() { echo -e "  ${Y}⚠${RESET}  $1"; }

# ─── Очищення при виході ────────────────────────────
cleanup() {
    spin_stop
    echo ""
    if [[ -n "${APP_PID:-}" ]]; then
        kill "$APP_PID" 2>/dev/null && info "Python-процес зупинено (PID $APP_PID)"
    fi
    if [[ -n "${NGROK_PID:-}" ]]; then
        kill "$NGROK_PID" 2>/dev/null && info "ngrok зупинено (PID $NGROK_PID)"
    fi
    rm -f "$LOG_FILE" "$NGROK_LOG"
    echo ""
    center "До побачення! 👋" "$DIM"
    echo ""
}
trap cleanup EXIT INT TERM

# ════════════════════════════════════════════════════
#  ЗАСТАВКА
# ════════════════════════════════════════════════════
clear
echo ""
top_border
echo -e "  ${DIM}│${RESET}$(printf '%*s' $((TW-4)) '')${DIM}│${RESET}"
center "${BOLD}${C}  🚀  PYTHON · VENV · NGROK  LAUNCHER  ${RESET}"
echo -e "  ${DIM}│${RESET}$(printf '%*s' $((TW-4)) '')${DIM}│${RESET}"
separator
box_line "venv:"    "$VENV_DIR"
box_line "Скрипт:"  "$APP_FILE"
box_line "Порт:"    "$APP_PORT"
box_line "Регіон:"  "$NGROK_REGION"
echo -e "  ${DIM}│${RESET}$(printf '%*s' $((TW-4)) '')${DIM}│${RESET}"
bot_border
echo ""

# ════════════════════════════════════════════════════
#  КРОК 1 — Перевірка залежностей
# ════════════════════════════════════════════════════
center "[ КРОК 1 / 4 ]  Перевірка середовища" "$BOLD$Y"
echo ""

spin_start "Шукаю python3..."
if ! command -v python3 &>/dev/null; then
    fail "python3 не знайдено. Встановіть Python 3.8+"
    exit 1
fi
PY_VER=$(python3 --version 2>&1)
ok "python3 знайдено — $PY_VER"

spin_start "Шукаю ngrok..."
if ! command -v ngrok &>/dev/null; then
    fail "ngrok не знайдено. Встановіть: https://ngrok.com/download"
    exit 1
fi
NGROK_VER=$(ngrok version 2>&1 | head -1)
ok "ngrok знайдено — $NGROK_VER"
echo ""

# ════════════════════════════════════════════════════
#  КРОК 2 — Активація venv
# ════════════════════════════════════════════════════
center "[ КРОК 2 / 4 ]  Активація venv" "$BOLD$Y"
echo ""

ACTIVATE="$VENV_DIR/bin/activate"
if [[ ! -f "$ACTIVATE" ]]; then
    warn "venv не знайдено за шляхом '$VENV_DIR'. Створюю..."
    spin_start "Створюю віртуальне оточення..."
    python3 -m venv "$VENV_DIR" >> "$LOG_FILE" 2>&1 || {
        fail "Не вдалося створити venv. Перевірте лог: $LOG_FILE"
        exit 1
    }
    ok "venv створено в '$VENV_DIR'"
fi

spin_start "Активую venv..."
# shellcheck source=/dev/null
source "$ACTIVATE"
ok "venv активовано"

# Встановлення залежностей якщо є requirements.txt
if [[ -f "requirements.txt" ]]; then
    spin_start "Встановлюю залежності з requirements.txt..."
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || {
        fail "Помилка при встановленні пакетів. Лог: $LOG_FILE"
        exit 1
    }
    ok "Залежності встановлено"
else
    info "requirements.txt не знайдено — пропускаю"
fi
echo ""

# ════════════════════════════════════════════════════
#  КРОК 3 — Запуск Python-застосунку
# ════════════════════════════════════════════════════
center "[ КРОК 3 / 4 ]  Запуск Python-застосунку" "$BOLD$Y"
echo ""

if [[ ! -f "$APP_FILE" ]]; then
    fail "Файл '$APP_FILE' не знайдено!"
    info "Встановіть змінну: APP_FILE=your_app.py ./launch.sh"
    exit 1
fi

spin_start "Запускаю $APP_FILE на порту $APP_PORT..."
python3 "$APP_FILE" >> "$LOG_FILE" 2>&1 &
APP_PID=$!

sleep 2

if ! kill -0 "$APP_PID" 2>/dev/null; then
    fail "Застосунок впав одразу після запуску. Лог:"
    echo ""
    cat "$LOG_FILE" | tail -20 | while IFS= read -r line; do
        echo -e "     ${DIM}$line${RESET}"
    done
    exit 1
fi
ok "Застосунок запущено (PID $APP_PID)"
echo ""

# ════════════════════════════════════════════════════
#  КРОК 4 — Запуск ngrok
# ════════════════════════════════════════════════════
center "[ КРОК 4 / 4 ]  Запуск ngrok тунелю" "$BOLD$Y"
echo ""

spin_start "Піднімаю ngrok тунель на порту $APP_PORT..."
ngrok http "$APP_PORT" \
    --region="$NGROK_REGION" \
    --log=stdout \
    --log-format=json > "$NGROK_LOG" 2>&1 &
NGROK_PID=$!

# Чекаємо поки ngrok видасть URL
MAX_WAIT=20
WAITED=0
NGROK_URL=""
while [[ -z "$NGROK_URL" && $WAITED -lt $MAX_WAIT ]]; do
    sleep 0.5
    WAITED=$((WAITED+1))
    NGROK_URL=$(grep -o '"url":"https://[^"]*"' "$NGROK_LOG" 2>/dev/null \
        | head -1 | sed 's/"url":"//;s/"//' || true)
done

if [[ -z "$NGROK_URL" ]]; then
    # Спробуємо через API
    sleep 2
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null \
        | grep -o '"public_url":"https://[^"]*"' | head -1 \
        | sed 's/"public_url":"//;s/"//' || true)
fi

spin_stop

if [[ -z "$NGROK_URL" ]]; then
    fail "Не вдалося отримати публічний URL від ngrok"
    warn "Можливі причини:"
    info "  • Не авторизовано: запустіть 'ngrok config add-authtoken YOUR_TOKEN'"
    info "  • ngrok вже запущено на іншому порту"
    info "  • Спробуйте вручну: ngrok http $APP_PORT"
    exit 1
fi

# ════════════════════════════════════════════════════
#  РЕЗУЛЬТАТ
# ════════════════════════════════════════════════════
echo ""
top_border
echo -e "  ${DIM}│${RESET}$(printf '%*s' $((TW-4)) '')${DIM}│${RESET}"
center "${BOLD}${G}  ✅  ГОТОВО! ВСЕ ЗАПУЩЕНО  ${RESET}"
echo -e "  ${DIM}│${RESET}$(printf '%*s' $((TW-4)) '')${DIM}│${RESET}"
separator
box_line "Публічний URL:"  "$NGROK_URL"           "$G$BOLD"
box_line "Локальний URL:"  "http://localhost:$APP_PORT"
box_line "Python PID:"     "$APP_PID"
box_line "ngrok PID:"      "$NGROK_PID"
box_line "Логи:"           "$LOG_FILE"
echo -e "  ${DIM}│${RESET}$(printf '%*s' $((TW-4)) '')${DIM}│${RESET}"
separator
echo -e "  ${DIM}│${RESET}  ${DIM}Натисніть Ctrl+C щоб зупинити все${RESET}$(printf '%*s' $((TW-40)) '')${DIM}│${RESET}"
echo -e "  ${DIM}│${RESET}$(printf '%*s' $((TW-4)) '')${DIM}│${RESET}"
bot_border

# ── Копіювання URL в буфер (якщо xclip/pbcopy доступні) ──
if command -v xclip &>/dev/null; then
    echo -n "$NGROK_URL" | xclip -selection clipboard 2>/dev/null && \
        info "URL скопійовано в буфер обміну"
elif command -v xsel &>/dev/null; then
    echo -n "$NGROK_URL" | xsel --clipboard --input 2>/dev/null && \
        info "URL скопійовано в буфер обміну"
fi

echo ""

# ════════════════════════════════════════════════════
#  МОНІТОРИНГ — живий хвіст логів
# ════════════════════════════════════════════════════
center "[ ЛОГИ ЗАСТОСУНКУ ]" "$DIM"
echo -e "  ${DIM}$(line ─ $((TW-4)))${RESET}"
echo ""

tail -f "$LOG_FILE" 2>/dev/null &
TAIL_PID=$!

# Чекаємо Ctrl+C або завершення застосунку
wait "$APP_PID" 2>/dev/null || true
kill "$TAIL_PID" 2>/dev/null || true

echo ""
warn "Застосунок завершився"
