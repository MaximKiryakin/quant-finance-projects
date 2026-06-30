import pandas as pd
import matplotlib.pyplot as plt
# функции автокорреляционной ф-ии и частичной автокорреляционной ф-ии
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from sklearn.metrics import (
    mean_squared_error,
    mean_absolute_error,
    mean_absolute_percentage_error,
    root_mean_squared_error
)

def plotTimeSeries(data: pd.DataFrame, X:str, y:str, axs=None, xlabel:str ="",
                   ylabel:str ="", title:str="", savePath="", **kwargs):

    if axs is not None:
        ax = axs
    else:
        fig, ax = plt.subplots(1, 1, figsize=(15, 3))
    
    ax.plot(data[X], data[y],  **kwargs)
    
    ax.set_title(title)
    ax.set_xlabel(X if xlabel == "" else xlabel)
    ax.set_ylabel(y if ylabel == "" else ylabel)
    ax.xaxis.set_major_locator(plt.MaxNLocator(10))

    if "label" in kwargs.keys():
        plt.legend()

    if savePath != "":
        plt.savefig(savePath, bbox_inches='tight')
    
    plt.grid(True)        
    return ax

def plotAcfPacf(data: pd.DataFrame, y: str, savePath: str = ""):
    fig, ax = plt.subplots(1, 2, figsize=(15, 3))
    _ = plot_acf(data["sales"], ax=ax[0])
    _ = plot_pacf(data["sales"], ax=ax[1])
    
    ax[0].set_ylim(-1.1, 1.1)
    ax[1].set_ylim(-1.1, 1.1)

    if savePath != "":
        plt.savefig(savePath, bbox_inches='tight')

def errorsCheck(y_true, y_pred):
    mse = mean_squared_error(y_true, y_pred)
    rmse = root_mean_squared_error(y_true, y_pred)
    mae = mean_absolute_error(y_true, y_pred)
    mape = mean_absolute_percentage_error(y_true, y_pred)
    
    return pd.DataFrame([("MSE", mse),
    ("RMSE", rmse),
    ("MAE", mae),
    ("Процентная ошибка", mape)], columns=["metric", "value"])