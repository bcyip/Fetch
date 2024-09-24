#!/usr/bin/env bats

# Setup step prior to each test
setup() {
  export API_KEY=$GEOLOC_API_KEY
  export OG_DEBUG=$DEBUG
  export DEBUG=false
}

teardown(){
  # reset debug value before tests execution
  export DEBUG=$OG_DEBUG
}
@test "Valid short option city and state" {
  run bash ./geoloc-util.sh -l "Denver, CO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, CO, US"* ]]
  [[ "$output" == *"Latitude: 39.7392364"* ]]
  [[ "$output" == *"Longitude: -104.984862"* ]]
}

@test "Valid short option zip code" {
  run bash ./geoloc-util.sh -l "80218"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, US"* ]]
  [[ "$output" == *"Latitude: 39.7327"* ]]
  [[ "$output" == *"Longitude: -104.9717"* ]]
}

@test "Valid zip code but no match" {
  # valid as in 5 numbers, but not an actual zip code in use
  run bash ./geoloc-util.sh -l "00000"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Zip Code Not Found"* ]]
}

@test "Valid long option city and state" {
  run bash ./geoloc-util.sh --locations "Denver, CO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, CO, US"* ]]
  [[ "$output" == *"Latitude: 39.7392364"* ]]
  [[ "$output" == *"Longitude: -104.984862"* ]]
}

@test "Valid city and long form state" {
  run bash ./geoloc-util.sh --locations "Denver, Colorado"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, CO, US"* ]]
  [[ "$output" == *"Latitude: 39.7392364"* ]]
  [[ "$output" == *"Longitude: -104.984862"* ]]
}

@test "Valid long option zip code" {
  run bash ./geoloc-util.sh --locations "80218"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, US"* ]]
  [[ "$output" == *"Latitude: 39.7327"* ]]
  [[ "$output" == *"Longitude: -104.9717"* ]]
}

@test "2 city-state locations" {
  run bash ./geoloc-util.sh --locations "Chicago, IL" "Denver, CO"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, CO, US"* ]]
  [[ "$output" == *"Latitude: 39.7392364"* ]]
  [[ "$output" == *"Longitude: -104.984862"* ]]
  [[ "$output" == *"Location: Chicago, IL, US"* ]]
  [[ "$output" == *"Latitude: 41.8755616"* ]]
  [[ "$output" == *"Longitude: -87.6244212"* ]]
}

@test "Mix of City and Zip" {
  run bash ./geoloc-util.sh --locations "Chicago, IL" "80218" "Denver, CO" "12345"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, CO, US"* ]]
  [[ "$output" == *"Latitude: 39.7392364"* ]]
  [[ "$output" == *"Longitude: -104.984862"* ]]
  [[ "$output" == *"Location: Denver, US"* ]]
  [[ "$output" == *"Latitude: 39.7327"* ]]
  [[ "$output" == *"Longitude: -104.9717"* ]]
  [[ "$output" == *"Location: Chicago, IL, US"* ]]
  [[ "$output" == *"Latitude: 41.8755616"* ]]
  [[ "$output" == *"Longitude: -87.6244212"* ]]
  [[ "$output" == *"Location: Schenectady, US"* ]]
  [[ "$output" == *"Latitude: 42.8142"* ]]
  [[ "$output" == *"Longitude: -73.9396"* ]]
}

@test "2 zip locations" {
  run bash ./geoloc-util.sh --locations "80218" "12345"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Location: Denver, US"* ]]
  [[ "$output" == *"Latitude: 39.7327"* ]]
  [[ "$output" == *"Longitude: -104.9717"* ]]
  [[ "$output" == *"Location: Schenectady, US"* ]]
  [[ "$output" == *"Latitude: 42.8142"* ]]
  [[ "$output" == *"Longitude: -73.9396"* ]]
}

@test "Invalid zip code -lt 5 digits" {
  run bash ./geoloc-util.sh --locations "123"
  [ "$status" -eq 1 ]
  [[ "$output" == "Invalid Zip or City, State" ]]
}

@test "Invalid zip code -gt 5 digits" {
  run bash ./geoloc-util.sh --locations "123456"
  [ "$status" -eq 1 ]
  [[ "$output" == "Invalid Zip or City, State" ]]
}

@test "No response from API for nonexistent place" {
  run bash ./geoloc-util.sh --locations "Nonexistent Place"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No Response Provided for: Nonexistent Place"* ]]
}

@test "Invalid verbose option" {
  run bash ./geoloc-util.sh --invalid "Denver, CO"
  [ "$status" -eq 1 ]
  echo "output comparing $output"
  [[ "$output" == "--invalid is an Invalid Option" ]]
}

@test "Invalid option" {
  run bash ./geoloc-util.sh -i "Denver, CO"
  [ "$status" -eq 1 ]
  [[ "$output" == "-i is an Invalid Option" ]]
}
#
@test "No arguments provided" {
  run bash ./geoloc-util.sh
  [ "$status" -eq 1 ]
  [ "$output" = "Usage: geoloc-util.sh [OPTIONS] \"City, State\" \"ZipCode\" ...

This script fetches geolocation data from the OpenWeather API based on city/state names or zip codes.

Options:
  -h, --help          Display this help message and exit.
  -l, --locations     Output the geolocation from geocoding API

Arguments:
  -l \"City, State\"    Specify one or more locations in the format \"City, State\".
                      Examples: \"Denver, CO\", \"New York, NY\"
  -l \"zipcode\"

Examples:
  geoloc-util.sh --locations \"Denver, CO\"
  geoloc-util.sh --locations \"80218\"
  geoloc-util.sh --locations \"Denver, CO\" \"80218\"" ]
}

@test "Not connected to internet" {
  skip
  # need to simulate disconnected internet
}
