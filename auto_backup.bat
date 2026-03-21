@echo off
cd /d "c:\Users\Blanco\Desktop\fivem"

:: Ajouter tous les fichiers (sauf ceux dans .gitignore)
git add .

:: Créer un commit avec la date et l'heure actuelle
git commit -m "Auto backup %date% %time%"

:: Envoyer vers GitHub sur la branche principale (main ou master)
git push origin main
