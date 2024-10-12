#!/bin/bash

# Funció per demanar la URL amb un valor per defecte
function prompt {
  local prompt_text=$1
  local default_value=$2
  read -p "$prompt_text ($default_value): " input_value
  echo ${input_value:-$default_value}
}

# Valor per defecte per la URL de descàrrega directa de Google Drive
default_url="https://drive.google.com/uc?export=download&id=ID_DEL_FITXER"

# Demanar la URL a l'usuari amb un valor per defecte
download_url=$(prompt "Introdueix la URL de descàrrega directa de l'script" "$default_url")

# Nom de l'arxiu descarregat
file_name="installacio-odoo_v16-postgres_v14.sh"

# Descarregar l'arxiu des de la URL proporcionada
echo "Descarregant l'script des de $download_url..."
wget -O "$file_name" "$download_url"

# Comprovar si la descàrrega ha estat correcta
if [ $? -eq 0 ]; then
  echo "L'script s'ha descarregat correctament com a $file_name"
  
  # Fer l'script executable
  chmod +x "$file_name"
  echo "S'ha fet l'script executable."

  # Executar l'script
  echo "Executant l'script..."
  ./"$file_name"
else
  echo "Error: No s'ha pogut descarregar l'arxiu des de la URL proporcionada."
fi

