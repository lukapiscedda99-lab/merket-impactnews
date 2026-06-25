
FROM mcr.microsoft.com/powershell
WORKDIR /app
COPY . .
CMD ["pwsh", "./crea_pacchetto_condivisione.ps1"]
