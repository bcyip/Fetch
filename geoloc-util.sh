#!/bin/bash

# OpenWeather API key
API_KEY=$GEOLOC_API_KEY

# Function to log debug messages
log_debug() {
  if [ "$DEBUG" = true ]; then
    echo "DEBUG: $1" >&2
  fi
}

help_message() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] "City, State" "ZipCode" ...

This script fetches geolocation data from the OpenWeather API based on city/state names or zip codes.

Options:
  -h, --help          Display this help message and exit.
  -l, --locations     Output the geolocation from geocoding API

Arguments:
  -l "City, State"    Specify one or more locations in the format "City, State".
                      Examples: "Denver, CO", "New York, NY"
  -l "zipcode"

Examples:
  $(basename "$0") --locations "Denver, CO"
  $(basename "$0") --locations "80218"
  $(basename "$0") --locations "Denver, CO" "80218"

EOF
}

# ensure we are able to reach openweathermap
check_url_connect() {
  if nc -zw1 openweathermap.org 443; then
    log_debug "openweathermap.org is online"
else
    log_debug "cannot reach openweathermap.org"
    echo "Unable to reach openweathermap.org
    please check that you are connected to the internet and openweathermap is up"
    exit 1
fi
}

# Function to query the geocoding API by city and state
query_city_state() {
  local location=$1
  local city=$(echo "$location" | cut -d',' -f1 | xargs)
  # account for multi-word cities
  city=$(echo "$city" | sed 's/ /%20/g')
  local state=$(echo "$location" | cut -d',' -f2 | xargs)
  # account for multi-word states, allows for state code & full word
  state=$(echo "$state" | sed 's/ /%20/g')
  local response=$(curl -s "http://api.openweathermap.org/geo/1.0/direct?q=${city},${state},US&limit=1&appid=${API_KEY}")
  echo "$response"
}

# Function to query the geocoding API by zip code
query_zipcode() {
  local zipcode=$1
  local response=$(curl -s "http://api.openweathermap.org/geo/1.0/zip?zip=${zipcode},US&appid=${API_KEY}")
  echo "$response"
}

# Function to parse and print the response
print_response() {
  local response=$1
  # Used for debugging
  log_debug "Response RAW: $response" >&2
  if [[ "$response" == "[]" ]]; then
    empty_response=1
  elif [[ $(echo "$response" | jq -r '.cod') == "404" ]]; then
    # Unable to match zip code
    empty_response=2
  elif echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
    # It's an array (city/state response)
    local lat=$(echo "$response" | jq -r '.[0].lat')
    local lon=$(echo "$response" | jq -r '.[0].lon')
    local name=$(echo "$response" | jq -r '.[0].name')
    local state=$(echo "$response" | jq -r '.[0].state // empty')
    local country=$(echo "$response" | jq -r '.[0].country')
  else
    # It's an object (zip code response)
    local lat=$(echo "$response" | jq -r '.lat')
    local lon=$(echo "$response" | jq -r '.lon')
    local name=$(echo "$response" | jq -r '.name')
    local state=$(echo "$response" | jq -r '.state // empty')
    local country=$(echo "$response" | jq -r '.country')
  fi

  if [[ $empty_response -eq 1 ]]; then
    # city/state gets through parser and geoloc returns empty result
    echo "No Response Provided for: $location"
    echo "-------------------------"
  elif [[ $empty_response -eq 2 ]]; then
    # zip code gets through parser and geoloc returns 404 for non matching zip
    echo "Zip Code Not Found"
    echo "-------------------------"
  else
    #zip does not return state, modify output
    if [[ -n "$state" ]]; then
      state=" ${state},"
    fi

    echo "Location: $name,$state $country"
    echo "Latitude: $lat"
    echo "Longitude: $lon"
    echo "-------------------------"
  fi
}

log_debug "all arguments: $@" >&2
log_debug "# arguments: $#" >&2

# Check if API Key set
if [[  -z "$API_KEY" ]]; then
  echo "Please set the API Key"
  exit 1
fi

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  help_message
  exit 1
fi

opt_flag=1
# parse for verbose or single char opt and if no opt
if [[ $1 =~ ^-- ]]; then
  option="${1:2}"
elif [[ $1 =~ ^- ]]; then
  option="${1:1}"
else #when no option use default behavior
  option="l"
  opt_flag=0
fi

case $option in
  l | locations)

    if [[ $opt_flag -eq 1 ]]; then
      # shift only if option was specified
      shift
    fi
    # Process each argument
    for location in "$@"; do
      if [[ $location =~ ^[0-9]{5}$ ]]; then
        log_debug "valid zip code"
        # It's a zip code
        response=$(query_zipcode "$location")
      elif [[ $location =~ ^[a-zA-Z]+([[[:space:]]-][a-zA-Z]+)*$,[[:space:]][A-Z]{2}|[a-zA-Z]+$ ]]; then
        log_debug "valid city/state"
        # It's a city and state
        # regex accounts for
        response=$(query_city_state "$location")
      else
        # exit with bad argument, faster feedback by preventing endpoint request
        echo "Invalid Zip or City, State"
        exit 1
      fi
      # Print the parsed response
      print_response "$response"
    done
    ;;
  h| help)
    help_message
    ;;
  *) #invalid option
    echo "$1 is an Invalid Option"
    exit 1
    ;;
esac
