#!/bin/bash

#!/bin/bash

# Funció per generar una contrasenya aleatòria de 16 caràcters
function generate_random_password {
  echo "$(tr -dc 'A-Za-z0-9?¿¡!@#$%^&*()_+=-' < /dev/urandom | head -c 16)"
}

# Funció per demanar dades obligatòries amb o sense valor per defecte
function prompt_required {
  local prompt_text=$1
  local default_value=$2

  # Si hi ha un valor per defecte, mostrar-lo en groc
  if [ -z "$default_value" ]; then
    read -p "$prompt_text: " input_value
  else
    read -p "$prompt_text: ($default_value)" input_value
  fi

  echo ${input_value:-$default_value}
}

# Funció per demanar dades amb validació "s/n", amb resposta per defecte a "s"
function prompt_yes_no {
  local prompt_text=$1
  local default_value=$2
  read -p "$prompt_text (s/n): ($default_value)" input_value
  input_value=${input_value:-$default_value}
  while [[ ! "$input_value" =~ ^[sSnN]$ ]]; do
    read -p "$prompt_text (s/n): ($default_value)" input_value
    input_value=${input_value:-$default_value}
  done
  echo "$input_value"
}

# Demanar el nom de la instància abans de tot
echo
echo -e "\e[1m\e[34mIntroduïu les dades del vostre Odoo\e[0m"
echo 
instance_name=$(prompt_required "Introdueix el nom de la instància de Lightsail")

# Generar valors per defecte per la base de dades i l'usuari basats en el nom de la instància
db_name_default=$(echo "${instance_name}_db" | tr '-' '_')
db_user_default=$(echo "${instance_name}_user" | tr '-' '_')

# Generar contrasenyes aleatòries per defecte
master_password_default=$(generate_random_password)
db_password_default=$(generate_random_password)
admin_password_default=$(generate_random_password)

# Demanar la resta de paràmetres amb els valors per defecte calculats
static_ip=$(prompt_required "Introdueix la IP estàtica de la instància")

# Generar el valor per defecte del domini dinàmicament
custom_domain_default="intranet.${instance_name}.com"
custom_domain=$(prompt_required "Introdueix el nom de domini" "$custom_domain_default")

master_password=$(prompt_required "Introdueix la contrasenya Màster" "$master_password_default")
db_name=$(prompt_required "Introdueix el nom de la base de dades" "$db_name_default")
db_user=$(prompt_required "Introdueix el nom d'usuari de la base de dades" "$db_user_default")
db_password=$(prompt_required "Introdueix la contrasenya de l'usuari de la base de dades" "$db_password_default")
admin_email=$(prompt_required "Introdueix el correu electrònic de l'administrador" "it@humancta.org")
admin_password=$(prompt_required "Introdueix la contrasenya de l'administrador" "$admin_password_default")

# Demanar idioma i país amb valors per defecte
admin_language=$(prompt_required "Introdueix l'idioma" "Català")
admin_country=$(prompt_required "Introdueix el país" "Spain")

echo 
install_demo_data=$(prompt_yes_no "Vols instal·lar dades de mostra? (s/n)" "n")

# Convertir la resposta de "s" o "n" en booleà per la configuració
if [[ "$install_demo_data" == "s" || "$install_demo_data" == "S" ]]; then
  demo_data="True"
else
  demo_data="False"
fi

# Llista completa de mòduls d'Odoo 16 per defecte amb noms en català
default_modules=(
  "sales_management (Gestió de vendes)"
  "crm (Gestió de clients)"
  "account (Comptabilitat)"
  "purchase (Compres)"
  "inventory (Inventari)"
  "project (Projectes)"
  "hr (Recursos humans)"
  "website (Lloc web)"
  "mail (Correu)"
  "calendar (Calendari)"
  "contacts (Contactes)"
  "point_of_sale (Punt de venda)"
  "mrp (Manufactura)"
  "stock (Gestió d'inventaris)"
  "sale (Gestió de comandes)"
  "fleet (Gestió de flotes)"
  "hr_holidays (Gestió de vacances)"
  "hr_expense (Despeses)"
  "website_sale (E-commerce)"
  "sale_management (Gestió de vendes)"
  "l10n_generic_coa (Pla general comptable)"
  "account_accountant (Comptabilitat avançada)"
  "account_asset (Gestió d'actius)"
  "hr_recruitment (Reclutament)"
  "maintenance (Manteniment)"
  "mrp_account (Comptabilitat de manufactura)"
  "website_crm (Gestió de clients en línia)"
  "event (Gestió d'esdeveniments)"
  "website_event (Esdeveniments al lloc web)"
  "website_blog (Blog del lloc web)"
)

# Llista de Server Tools disponibles
server_tools_modules=(
  "base_setup (Configuració de base)"
  "base_automation (Automatització)"
  "auditlog (Registre d'auditories)"
  "cron (Gestió de tasques programades)"
  "dbfilter_from_header (Filtre de base de dades per capçalera)"
)

# Arrays per guardar mòduls seleccionats
selected_default_modules=()
selected_server_tools=()

# Pregunta si es volen instal·lar tots els mòduls per defecte
echo 
read -p 'Vols instal·lar tots els mòduls per defecte? (s/n): (s) ' install_all_modules
install_all_modules=${install_all_modules:-s}

if [[ "$install_all_modules" == "s" || "$install_all_modules" == "S" ]]; then
  echo "Tots els mòduls predeterminats seleccionats"
  for module in "${default_modules[@]}"; do
    module_name=$(echo $module | cut -d' ' -f1)
    selected_default_modules+=("$module_name")
  done
else
  echo "Selecciona els mòduls d'Odoo que vols instal·lar (s/n, 's' per defecte per a tots):"
  for module in "${default_modules[@]}"; do
    read -p "$module (s/n): (s) " choice
    choice=${choice:-s}
    if [[ "$choice" == "s" || "$choice" == "S" ]]; then
      module_name=$(echo $module | cut -d' ' -f1)
      selected_default_modules+=("$module_name")
      echo "Mòdul $module_name seleccionat"
    fi
  done
fi

# Pregunta si es volen instal·lar tots els Server Tools per defecte
echo 
read -p 'Vols instal·lar tots els Server Tools per defecte? (s/n): (s) ' install_all_tools
install_all_tools=${install_all_tools:-s}

if [[ "$install_all_tools" == "s" || "$install_all_tools" == "S" ]]; then
  echo "Tots els Server Tools predeterminats seleccionats"
  for tool in "${server_tools_modules[@]}"; do
    tool_name=$(echo $tool | cut -d' ' -f1)
    selected_server_tools+=("$tool_name")
  done
else
  echo "Selecciona els Server Tools que vols instal·lar (s/n, 's' per defecte per a tots):"
  for tool in "${server_tools_modules[@]}"; do
    read -p "$tool (s/n): (s) " choice
    choice=${choice:-s}
    if [[ "$choice" == "s" || "$choice" == "S" ]]; then
      tool_name=$(echo $tool | cut -d' ' -f1)
      selected_server_tools+=("$tool_name")
      echo "Server Tool $tool_name seleccionat"
    fi
  done
fi

# Confirmació final dels mòduls seleccionats
echo -e "\e[1m\e[34mMòduls seleccionats per a la instal·lació:\e[0m"
for module in "${selected_default_modules[@]}"; do
  echo "- $module"
done

echo -e "\e[1m\e[34mServer Tools seleccionats per a la instal·lació:\e[0m"
for tool in "${selected_server_tools[@]}"; do
  echo "- $tool"
done

# Confirmar abans de continuar
echo 
read -p 'Vols continuar amb aquests mòduls seleccionats? (s/n) (s): ' confirm_modules
confirm_modules=${confirm_modules:-s}
if [[ $confirm_modules != "s" ]]; then
  echo "Instal·lació cancel·lada."
  exit 1
fi

# Mostrar els valors seleccionats
function mostrar_valors {
  echo -e "\e[1m\e[33mConfiguració seleccionada:\e[0m"
  echo "  Nom de la instància de Lightsail: $instance_name"
  echo "  IP estàtica de la instància: $static_ip"
  echo "  Nom de domini: $custom_domain"
  echo "  Master Password: $master_password"
  echo "  Nom de la base de dades: $db_name"
  echo "  Usuari de la base de dades: $db_user"
  echo "  Contrasenya de la base de dades: $db_password"
  echo "  Correu electrònic de l'administrador: $admin_email"
  echo "  Contrasenya de l'administrador: $admin_password"
  echo "  Idioma: $admin_language"
  echo "  País: $admin_country"
  echo "  Instal·lació de dades de mostra: $demo_data"
  echo "  Mòduls per defecte seleccionats: ${selected_default_modules[*]}"
  echo "  Server Tools seleccionats: ${selected_server_tools[*]}"
}

# Confirmar els valors abans de continuar
mostrar_valors

read -p 'Vols continuar la instal·lació amb aquests valors? (s/n): (s) ' confirm
confirm=${confirm:-s}  # Si l'usuari no introdueix res, assigna 's' per defecte

if [[ $confirm != "s" ]]; then
  echo "Instal·lació cancel·lada."
  exit 1
fi

# Actualitzar el servidor
echo  
echo -e "\e[1m\e[34mActualitzant el servidor...\e[0m"
sudo apt update -y && sudo apt upgrade -y

# Instal·lació de seguretat SSH i Fail2ban
echo  
echo -e "\e[1m\e[34mInstal·lant seguretat SSH i Fail2ban...\e[0m"
sudo apt-get install openssh-server fail2ban -y

# Instal·lació de llibreries necessàries
echo  
echo -e "\e[1m\e[34mInstal·lant llibreries necessàries...\e[0m"
sudo apt install vim curl wget gpg git gnupg2 software-properties-common apt-transport-https lsb-release ca-certificates -y
sudo apt install build-essential wget git python3 python3-pip python3-dev python3-venv python3-wheel libfreetype6-dev libxml2-dev libzip-dev libsasl2-dev python3-setuptools libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libldap2-dev libtiff5-dev libopenjp2-7-dev -y

# Instal·lació de Node.js i NPM
echo  
echo -e "\e[1m\e[34mInstal·lant Node.js i NPM...\e[0m"
sudo apt install nodejs npm node-less xfonts-75dpi xfonts-base fontconfig -y
sudo npm install -g rtlcss

# Instal·lació de Wkhtmltopdf
echo  
echo -e "\e[1m\e[34mInstal·lant Wkhtmltopdf...\e[0m"
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo apt-get install -f -y

# Instal·lació de PostgreSQL 14
echo  
echo -e "\e[1m\e[34mInstal·lant PostgreSQL 14...\e[0m"
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-14 postgresql-client-14

# Creació de la base de dades i usuari PostgreSQL per Odoo
echo  
echo -e "\e[1m\e[34mCreant base de dades i usuari PostgreSQL per Odoo...\e[0m"
sudo su - postgres -c "psql -c \"CREATE DATABASE $db_name;\""
sudo su - postgres -c "createuser -p 5432 -s $db_user"
sudo su - postgres -c "psql -c \"ALTER USER $db_user WITH PASSWORD '$db_password';\""

# Configurar autenticació PostgreSQL
echo  
echo -e "\e[1m\e[34mConfigurant autenticació PostgreSQL...\e[0m"
sudo bash -c "echo 'local   all             all                                     md5' >> /etc/postgresql/14/main/pg_hba.conf"
sudo systemctl restart postgresql

# Creació de l'usuari Odoo
echo  
echo -e "\e[1m\e[34mCreant usuari Odoo al sistema...\e[0m"
sudo adduser --system --group --home=/opt/odoo --shell=/bin/bash odoo

# Clonar el repositori Odoo 16
echo  
echo -e "\e[1m\e[34mClonant el repositori Odoo 16...\e[0m"
sudo su - odoo -c "git clone https://github.com/odoo/odoo.git --depth 1 --branch 16.0 --single-branch /opt/odoo/odoo-server"

# Crear entorn virtual de Python
echo  
echo -e "\e[1m\e[34mCreant entorn virtual de Python...\e[0m"
sudo su - odoo -c "python3 -m venv /opt/odoo/odoo-server/venv"
sudo su - odoo -c "/opt/odoo/odoo-server/venv/bin/pip install wheel"
sudo su - odoo -c "/opt/odoo/odoo-server/venv/bin/pip install -r /opt/odoo/odoo-server/requirements.txt"

# Funció per instal·lar mòduls seleccionats a la base de dades
install_selected_modules() {
  local modules_to_install=("$@")
  
  echo -e "\e[1m\e[34mInstal·lant mòduls seleccionats...\e[0m"
  
  for module in "${modules_to_install[@]}"; do
    echo -e "\e[1mInstal·lant el mòdul: $module\e[0m"
    sudo su - odoo -c "/opt/odoo/odoo-server/venv/bin/python3 /opt/odoo/odoo-server/odoo-bin -d $db_name -i $module --stop-after-init"
    
    if [ $? -eq 0 ]; then
      echo -e "\e[32mMòdul $module instal·lat correctament.\e[0m"
    else
      echo -e "\e[31mError: No s'ha pogut instal·lar el mòdul $module.\e[0m"
    fi
  done
}

# Instal·lar mòduls seleccionats
install_selected_modules "${selected_default_modules[@]}"

# Instal·lar Server Tools seleccionats
install_selected_modules "${selected_server_tools[@]}"

# Crear directori de logs
echo  
echo -e "\e[1m\e[34mCreant directori de logs...\e[0m"
sudo mkdir /var/log/odoo
sudo touch /var/log/odoo/odoo-server.log
sudo chown odoo:odoo /var/log/odoo -R
sudo chmod 777 /var/log/odoo

# Crear fitxer de configuració d'Odoo
echo  
echo -e "\e[1m\e[34mCreant fitxer de configuració d'Odoo...\e[0m"
sudo bash -c "cat > /etc/odoo.conf" <<EOL
[options]
instance_name = $instance_name
static_ip = $static_ip
port = 8069
master_password = $master_password
db_host = 127.0.0.1
db_port = 5432
db_user = $db_user
db_password = $db_password
db_name = $db_name
addons_path = /opt/odoo/odoo-server/addons,/opt/odoo/odoo-server/server-tools,/opt/odoo/odoo-server/custom_addons
logfile = /var/log/odoo/odoo-server.log
log_level  = debug
admin_passwd = $admin_password
admin_email = $admin_email
admin_country = $admin_country
admin_language = $admin_language
demo_data = $demo_data
EOL
sudo chown odoo:odoo /etc/odoo.conf

# Crear servei d'Odoo
echo  
echo -e "\e[1m\e[34mCreant servei d'Odoo...\e[0m"
sudo bash -c "cat > /etc/systemd/system/odoo-server.service" <<EOL
[Unit]
Description=Odoo Service
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo-server/venv/bin/python3 /opt/odoo/odoo-server/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOL

# Iniciar i habilitar el servei
echo  
echo -e "\e[1m\e[34mIniciant i habilitant el servei d'Odoo...\e[0m"
sudo systemctl daemon-reload
sudo systemctl start odoo-server
sudo systemctl enable odoo-server

# Instal·lació de Nginx
echo  
echo -e "\e[1m\e[34mInstal·lant Nginx...\e[0m"
sudo apt install nginx -y

# Configuració de Nginx
echo  
echo -e "\e[1m\e[34mConfigurant Nginx per Odoo...\e[0m"
sudo bash -c "cat > /etc/nginx/sites-available/$custom_domain" <<EOL
upstream odoo16 {
    server 127.0.0.1:8069;
}

server {
    listen 80;
    server_name $custom_domain;

    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    location / {
        proxy_pass http://odoo16;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOL

# Activar configuració Nginx
echo  
echo -e "\e[1m\e[34mActivant configuració Nginx...\e[0m"
sudo ln -s /etc/nginx/sites-available/$custom_domain /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

echo  
echo -e "\e[1m\e[34mEliminant arxius d'instal·lació...\e[0m"
# Esborrar els fitxers .deb baixats
sudo rm -f /home/ubuntu/*.deb
sudo rm -f /home/ubuntu/*.deb.*
# Esborrar l'script d'instal·lació i arxius associats
sudo rm -f /home/ubuntu/installacio-odoo_v16-postgres_v14.sh
sudo rm -f /home/ubuntu/.wget-hsts
# Netejar la cache d'apt
sudo apt-get clean
# Eliminar paquets innecessaris
sudo apt-get autoremove -y
# Opcional: esborrar logs antics (si n'hi ha)
sudo rm -f /var/log/odoo/*.log
echo  
echo "Fitxers temporals eliminats."

# Mostrar els valors seleccionats
function mostrar_valors {
  echo -e "\e[1m\e[33mConfiguració seleccionada:\e[0m"
  echo "  Nom de la instància de Lightsail: \e[33m$instance_name\e[0m"
  echo "  IP estàtica de la instància: \e[33m$static_ip\e[0m"
  echo "  Nom de domini: \e[33m$custom_domain\e[0m"
  echo "  Master Password: \e[33m$master_password\e[0m"
  echo "  Nom de la base de dades: \e[33m$db_name\e[0m"
  echo "  Usuari de la base de dades: \e[33m$db_user\e[0m"
  echo "  Contrasenya de la base de dades: \e[33m$db_password\e[0m"
  echo "  Correu electrònic de l'administrador: \e[33m$admin_email\e[0m"
  echo "  Contrasenya de l'administrador: \e[33m$admin_password\e[0m"
  echo "  Idioma: \e[33m$admin_language\e[0m"
  echo "  País: \e[33m$admin_country\e[0m"
  echo "  Instal·lació de dades de mostra: \e[33m$demo_data\e[0m"
  echo "  Mòduls per defecte seleccionats: \e[33m${selected_default_modules[*]}\e[0m"
  echo "  Server Tools seleccionats: \e[33m${selected_server_tools[*]}\e[0m"
}

mostrar_valors
echo  
echo "Accedeix a Odoo mitjançant el domini: https://$custom_domain o https://$static_ip:8069"
