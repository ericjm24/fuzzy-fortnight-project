import requests

class census():
    def __init__(self, api_key):
        self.api_key = api_key

    def get_FIPS_from_coord(self, coord, benchmark = 9, vintage=910):
        url = "https://geocoding.geo.census.gov/geocoder/geographies/coordinates?"
        url += f"x={coord[0]}&y={coord[1]}"
        url += f"&benchmark={benchmark}"
        url += f"&vintage={vintage}"
        url += "&format=json"
        response = requests.get(url)
        if response.status_code == 200:
            dat = response.json()["result"]["geographies"]
            #print(dat)
            out = {
                'state':dat["States"][0]['STATE'],
                'county':dat["Counties"][0]['COUNTY'],
                'tract':dat["Census Tracts"][0]['TRACT'],
                'block':dat["Census Blocks"][0]['BLOCK']
            }
        else:
            out = {}
        return out

    def get_population_from_coord(self, coord):
        addr = self.get_FIPS_from_coord(coord)
        url = "https://api.census.gov/data/2012/acs/acs5?get=NAME,B00001_001E&for="
        url += f"tract:{addr['tract']}"
        url += f"&in=county:{addr['county']}%20state:{addr['state']}"
        url += f"&key={self.api_key}"
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()

    def get_data_from_coord(self, coord, data_names={}):
        addr = self.get_FIPS_from_coord(coord)
        url = "https://api.census.gov/data/2012/acs/acs5?get=NAME"
        for s in data_names.keys():
            url += ',' + s
        url += f"&for=tract:{addr['tract']}"
        url += f"&in=county:{addr['county']}%20state:{addr['state']}"
        url += f"&key={self.api_key}"
        response=requests.get(url)
        if response.status_code == 200:
            dat = response.json()
            for t in range(len(dat[0])):
                if dat[0][t] in list(data_names.keys()):
                    dat[0][t] = data_names[dat[0][t]]
            return dat
