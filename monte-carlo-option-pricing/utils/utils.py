import numpy as np
import matplotlib.pyplot as plt

def plot_mc_paths(paths:np.ndarray, num_paths:int=10, title:str=None, save_path:str='logs/graphs'):
    """
    Визуализирует и сохраняет траектории Монте-Карло.
    
    Параметры:
        paths     : массив траекторий формы (N, m+1)
        num_paths : количество отображаемых траекторий
        title     : заголовок графика
        save_path : путь для сохранения графика
    """
    plt.figure(figsize=(10, 6))
    N = paths.shape[0]
    
    if N <= num_paths:
        idx = np.arange(N)
    else:
        idx = np.random.choice(N, size=num_paths, replace=False)
    
    for i in idx:
        plt.plot(paths[i], lw=1)
    
    title = title if title else f'Graph of {num_paths} random trajectories of CEV process.'
    plt.title(title), plt.xlabel('Time Steps'), plt.ylabel('Asset Price')
    plt.grid(True), plt.savefig(f'{save_path}/cev_mc.png', bbox_inches='tight')
    print(f'График `{title}` был сохранен: {save_path}/cev_mc.png')
    plt.close()


def simulate_cev(S0, r, q, sigma, gamma, T, m, N):
    """
    Симулирует траектории цены актива по модели CEV.
    
    Параметры:
        S0    : начальная цена актива
        r     : безрисковая процентная ставка
        q     : дивидендная доходность
        sigma : волатильность
        gamma : параметр гамма модели CEV
        T     : срок до погашения
        m     : количество шагов дискретизации
        N     : количество симуляций
    
    Возвращает:
        Массив траекторий размером (N, m+1)
    """
    dt = T / m
    S = np.zeros((N, m + 1))
    S[:, 0] = S0  # Начальное условие
    
    # Генерация случайных величин
    Z = np.random.normal(size=(N, m))
    
    for t in range(1, m + 1):
        drift = (r - q) * S[:, t-1] * dt
        diffusion = sigma * (S[:, t-1] ** gamma) * np.sqrt(dt) * Z[:, t-1]
        S[:, t] = S[:, t-1] + drift + diffusion
        S[:, t] = np.maximum(S[:, t], 0) 

    return S


def cliquet_price(S0, r, q, sigma, gamma, N, n, m, T, paths):
    """
    Вычисляет цену опциона cliquet методом Монте-Карло.
    
    Параметры:
        n : количество выплат (t_i = i*T/n)
    
    Возвращает:
        Оценку цены опциона и стандартную ошибку
    """
    # Симулируем траектории

    
    # Определяем моменты выплат в шагах дискретизации
    payoff_steps = np.linspace(0, m, n+1, dtype=int)
    
    # Вычисляем выплаты
    payoffs = np.zeros(N)
    for i in range(1, n+1):
        t_prev = payoff_steps[i-1]
        t_curr = payoff_steps[i]
        payoff = np.maximum(paths[:, t_curr] - paths[:, t_prev], 0)
        discount_factor = np.exp(-r * (i * T / n))  # Дисконтирование к моменту t_i
        payoffs += payoff * discount_factor
    
    # Оценка цены и стандартной ошибки
    price = np.mean(payoffs)
    std_error = np.std(payoffs) / np.sqrt(N)
    return price, std_error