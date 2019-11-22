import requests
from scipy.interpolate import PchipInterpolator
import pandas as pd
tracts = pd.read_csv("2019_Gaz_tracts_national.txt", delimiter='\t', dtype=str).groupby(by="USPS")
codes = {state[0]:state[1] for state in zip(tracts.groups.keys(), [x[:2] for x in tracts.head(1)['GEOID'].values])}
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
        url = "https://api.census.gov/data/2012/acs/acs5/profile?get=NAME,B00001_001E&for="
        url += f"tract:{addr['tract']}"
        url += f"&in=county:{addr['county']}%20state:{addr['state']}"
        url += f"&key={self.api_key}"
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()

    def get_data_from_FIPS(self, addr, year=2010, data_names={}):
        url = "https://api.census.gov/data/"
        url += str(int(year)) + "/acs/acs5/profile?get=NAME"
        for s in data_names.keys():
            url += ',' + s
        url += f"&for=tract:{addr['tract']}"
        url += f"&in=county:{addr['county']}%20state:{addr['state']}"
        url += f"&key={self.api_key}"
        response=requests.get(url)
        if response.status_code == 200:
            dat = response.json()
            outDict = {}
            for t in range(len(dat[0])):
                if dat[0][t] in list(data_names.keys()):
                    outDict[data_names[dat[0][t]]] = dat[1][t]
                else:
                    outDict[dat[0][t]] = dat[1][t]
            return outDict
        return None

    def get_tract_data_for_state(self, state='CA', year=2010, data_names={}):
        url = url = "https://api.census.gov/data/"
        url += str(int(year)) + "/acs/acs5/profile?get=NAME"
        for s in data_names.keys():
            url += ',' + s
        url += "&for=tract:*"
        url += f"&in=state:{codes[state]}"
        response=requests.get(url)
        if response.status_code == 200:
            dat = response.json()
            return dat
            outDict = {}
            for t in range(len(dat[0])):
                if dat[0][t] in list(data_names.keys()):
                    outDict[data_names[dat[0][t]]] = dat[1][t]
                else:
                    outDict[dat[0][t]] = dat[1][t]
            return outDict
        return None

    def get_data_from_coord(self, coord, year = 2010, data_names={}):
        addr = self.get_FIPS_from_coord(coord)
        return self.get_data_from_FIPS(addr, year, data_names)

    def get_data_all_years_from_coord(self, coord, data_names={}):
        addr = self.get_FIPS_from_coord(coord)
        dat = {2010:self.get_data_from_FIPS(addr, 2010, data_names)}
        for year in range(2010,2018):
            temp = self.get_data_from_FIPS(addr, year, data_names)
            dat[year] = temp
        return dat

    def get_data_spline_from_coord(self, coord, data_names):
        dat = self.get_data_all_years_from_coord(coord, data_names)
        out = dat[2010]
        for t in data_names.values():
            x = range(2010, 2018)
            y = [dat[z][t] for z in x]
            try:
                out[t] = PchipInterpolator(x,y)
            except ValueError:
                out[t] = None
        return out
