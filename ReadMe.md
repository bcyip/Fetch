## Documentation

1. **API Key**:
   - Set your API KEY by adding the env variable below
   ```
   export GEOLOC_API_KEY="your_api_key"
   ```

2. **Functions**:
   - `query_city_state`: Takes a location in the format "City, State" and queries the geocoding API.  State can be in the form of 2 char code or fully spelled out
   - `query_zipcode`: Takes a zip code and queries the geocoding API.

3. **Response Parsing**:
   - `print_response`: Parses the JSON response using `jq` to extract latitude, longitude, name, state, and country. It then prints these details.
   - Note: zip code query returns empty state

4. **Argument Handling**:
   - Processes each input argument. If the argument is a 5-digit number (zip code), call `query_zipcode`. Otherwise, assumes argument is a "City, State" combination and calls `query_city_state`.

5. **Error Handling**:
   - checks internet connection by verifying able to connect to openweathermap.org
   - options -h, --help, -l, --locations only, defaults when no options to --locations behavior
   - Ensures at least one argument is provided and handles multiple locations.
   -

### Application Dependencies
- Ensure you have `jq` installed for parsing JSON. You can install it using:
  ```bash
  brew install jq
  ```

### Usage
You can run the script as follows:
```bash
./geoloc-util --locations "Madison, WI" "12345" "Chicago, IL" "10001"
```

## Testing Documentation

### Application Dependencies
- Ensure you have bats-core installed
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Debug Mode
- To run with debug logging when executing script directly, export the following.
```
export DEBUG=true
./geoloc-util -l "80218"
```
- Note: running bats is set to default `DEBUG=false`.  If you would like to run bats with debug logging, update line 7 of test_geoloc_util.bats `export DEBUG=true`

### Run Tests
To run the tests, navigate to the directory containing your test file and execute the following command:
```
bats test_geoloc_util.bats
```
