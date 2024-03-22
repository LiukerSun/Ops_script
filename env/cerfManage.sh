#!/bin/bash
function check_acme_sh {
    if [ ! -f "$HOME/.acme.sh/acme.sh" ]; then
        curl https://get.acme.sh | sh
        source "$HOME/.bashrc"
    fi
}

function check_ssl_path {
    # check /etc/ssl is exist?
    if [ ! -d "/etc/ssl" ]; then
        echo "create /etc/ssl"
        sudo mkdir /etc/ssl
    fi
}

function check_account {
    local FILE_PATH="$HOME/.acme.sh/account.conf"
    if [ ! -f "$FILE_PATH" ]; then
        echo "account.conf do not exist."
        return 1
    fi

    if ! grep -q "ACCOUNT_EMAIL" "$FILE_PATH"; then
        echo "ACCOUNT_EMAIL not found in account.conf"
        return 1
    fi

    if ! grep -q "ACCOUNT_KEY_PATH" "$FILE_PATH"; then
        echo "ACCOUNT_KEY_PATH not found in account.conf"
        return 1
    fi

    echo "Account check passed."
    return 0
}

function create_account {
    read -p "Enter email: " email
    $HOME/.acme.sh/acme.sh --register-account -m "$email"

    if [ $? -eq 0 ]; then
        echo "ACCOUNT_EMAIL=$email" >>$HOME/.acme.sh/account.conf
        echo "ACCOUNT_KEY_PATH=$HOME/.acme.sh/account.key" >>$HOME/.acme.sh/account.conf
        echo "Account information has been saved."
    else
        echo "Failed to register account."
    fi
}

# list cret
function list_cert {
    $HOME/.acme.sh/acme.sh --list
    return 0
}

# cloudflare setting
function set_cloudflare {
    read -p "Enter your Cloudflare email: " CF_Email
    read -p "Enter your Cloudflare API key: " CF_Key
    export CF_Email=${CF_Email}
    export CF_Key=${CF_Key}
    echo "export CF_Email=${CF_Email}" >> ~/.bashrc
    echo "export CF_Key=${CF_Key}" >> ~/.bashrc
    echo "Cloudflare email and API key have been set and saved to ~/.bashrc."
}

# Alibaba setting
function set_alibaba {
    read -p "Enter your Alibaba API key: " Ali_Key
    read -p "Enter your Alibaba Ali_Secret: " Ali_Secret
    export Ali_Key=${Ali_Key}
    export Ali_Secret=${Ali_Secret}
    echo "export Ali_Key=${Ali_Key}" >> ~/.bashrc
    echo "export Ali_Secret=${Ali_Secret}" >> ~/.bashrc
    echo "Ali_Key and Ali_Secret have been set and saved to ~/.bashrc."
}

function create_domain_dir {
    sudo mkdir -p /etc/ssl/$domain
}

function create_certificate {
    read -p "Enter domain name: " domain
    create_domain_dir
    if [ "$dns_choice" == "1" ]; then
        dns_provider="dns_cf"
    elif [ "$dns_choice" == "2" ]; then
        dns_provider="dns_ali"
    else
        echo "Invalid choice"
        exit 1
    fi
    $HOME/.acme.sh/acme.sh --issue --dns $dns_provider -d "$domain" \
        --cert-file /etc/ssl/$domain/cert.pem \
        --key-file /etc/ssl/$domain/key.pem \
        --fullchain-file /etc/ssl/$domain/fullchain.pem \
        --reloadcmd "systemctl force-reload nginx"
    return 0
}

function remove_wrong_cert {
    certs=$($HOME/.acme.sh/acme.sh --list | tail -n +2)
    IFS=$'\n'
    for cert in $certs; do
        created_time=$(echo "$cert" | awk '{print $5}')
        if [[ "$created_time" == "" ]]; then
            domain=$(echo "$cert" | awk '{print $1}')
            $HOME/.acme.sh/acme.sh --remove --domain "$domain"
            rm -rf /etc/ssl/$domain
        fi
    done
    echo "Wrong certificates have been removed."
}

function renew_certificates {
    $HOME/.acme.sh/acme.sh --cron
    echo "Certificates have been renewed."
}

# start

check_acme_sh
check_ssl_path
if ! check_account; then
    create_account
fi

while :; do
    echo "1. List certificates"
    echo "2. Issue a new certificate"
    echo "3. Renew a certificate"
    echo "4. Remove a certificate"
    echo "5. Set Cloudflare email and API key"
    echo "6. Set Alibaba email and API key"
    echo "q. Quit"
    read -p "Enter your choice (1/2/3/4/5/6/q): " user_choice
    case $user_choice in
    1)
        list_cert
        ;;
    2)
        echo "1. Cloudflare"
        echo "2. Alibaba"
        echo "q. Quit"
        read -p "Enter your choice (1/2/q): " dns_choice
        create_certificate
        ;;
    3)
        renew_certificates
        ;;
    4)
        remove_wrong_cert
        ;;
    5)
        set_cloudflare
        ;;
    6)
        set_alibaba
        ;;
    q)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Please select again."
        ;;
    esac
done
