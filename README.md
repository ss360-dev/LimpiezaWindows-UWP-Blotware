❗ Este proyecto no es de código abierto. El uso de este script está restringido y regulado por SS360 SAS. Consulta el archivo LICENSE.txt.

# SS360 Limpieza Interactiva (Versión funcional confirmada)

Esta es la versión confirmada funcional sin soporte para selección por rangos. Permite seleccionar elementos para eliminar usando índices separados por coma (ej: `1,3,5`).

## Cómo ejecutar

1. Abre PowerShell como Administrador.
2. Ejecuta el siguiente comando:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\SS360-LimpiezaInteractiva.ps1"
```

## Características

- Detecta apps UWP no esenciales y entradas de inicio automático.
- Permite seleccionar qué eliminar.
- Genera un log detallado en la carpeta temporal del sistema.
- Reinicio automático opcional tras limpieza.


🧹 **Herramienta interactiva para limpieza de aplicaciones UWP y entradas de inicio automático en Windows 10/11.**

## ✅ Características
- Interfaz por pasos (PowerShell)
- Identificación de bloatware UWP
- Eliminación segura de apps y claves de inicio (HKCU y HKLM)
- Finalización de procesos relacionados
- Registro detallado con marca de tiempo
- Soporte para selección por índices o rangos
- Reinicio automático o salida con `Q`

## 📦 Requisitos
- Windows 10 u 11
- PowerShell 5.1 o superior
- Ejecutar como Administrador

## ▶️ Ejecución
```bash
powershell.exe -ExecutionPolicy Bypass -File ".\SS360-LimpiezaInteractiva.ps1"

🎯 Ejemplos de selección de elementos
> ¿Qué deseas eliminar?
1,3,5           ← Elimina elementos 1, 3 y 5
### -> sin soporte : 2-4,8-10        ← Elimina del 2 al 4 y del 8 al 10
A               ← Elimina todos
N               ← No elimina nada
Q               ← Sale sin cambios

🗂️ Log
El log se guarda en el directorio temporal del sistema:
%TEMP%\SS360-limpieza-log.txt
