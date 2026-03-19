#! /bin/bash

display_services() {
    echo "~~~~~ MY SALON ~~~~~"
    echo "Welcome to My Salon, how can I help you?"
    echo ""
    
    services=$(psql -U freecodecamp -d salon -t -A -F "|" -c "SELECT service_id, name FROM services ORDER BY service_id;")
    
    declare -g -A service_names
    while IFS="|" read -r id name; do
        if [[ -n $id && -n $name ]]; then
            service_names[$id]=$name
            echo "$id) $name"
        fi
    done <<< "$services"
    
    echo ""
}

main() {
    display_services
    
    read SERVICE_ID_SELECTED
    
    service_name=${service_names[$SERVICE_ID_SELECTED]}
    
    if [[ -z $service_name ]]; then
        echo -e "\nI could not find that service. What would you like today?"
        main
        return
    fi
    
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE
    
    customer_info=$(psql -U freecodecamp -d salon -t -A -F "|" -c "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE';")
    
    if [[ -z $customer_info ]]; then
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME
        
        psql -U freecodecamp -d salon -c "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME');" > /dev/null
        
        customer_id=$(psql -U freecodecamp -d salon -t -A -c "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")
    else
        IFS="|" read -r customer_id CUSTOMER_NAME <<< "$customer_info"
    fi
    
    echo -e "\nWhat time would you like your $service_name, $CUSTOMER_NAME?"
    read SERVICE_TIME
    
    psql -U freecodecamp -d salon -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($customer_id, $SERVICE_ID_SELECTED, '$SERVICE_TIME');" > /dev/null
    
    echo -e "\nI have put you down for a $service_name at $SERVICE_TIME, $CUSTOMER_NAME."
}

chmod +x salon.sh

main