import http.client
import json
import ssl
import time
import os
from firebase_functions import https_fn
import requests
from google.auth.transport import requests as grequests
from google.oauth2.id_token import verify_oauth2_token

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
    
def get_image_info(image_url):
    json_prompt = "Analyze the image and output information as a json object (and only the JSON) with the following fields: 1. description - required. containins a detailed description of what is in the image including prominent colors and vibes 2. playlistTitle - required. a playlist title that goes with the image description.  Example: \"Floating on air: A night with The Boss\" 3. music - optional.  If the image contains information on a band, music artist, or song, output the band name, artist name, or song name in this field. If there isn't anything, don't include this field. 4. genre - required. Output a broad music genre that best encapsulates the vibe of the image. It should be something like pop, country, indie, hip-hop, RNB, etc. 5. subgenre - required.  Choose a more specific and creative subgenre of the genre above that best represents the image. For example, indie pop is not specific enough. Feel free to include decades! 6. songlist - required.  Select 40 songs that fit the subgenre mentioned above. Some of these songs should be well known and some should be less popular to diverse the playlist. The songs should not mention the name of the genre or subgenre.  These should be real songs from real artists that I can find on Spotify. If there was a band, music artist, or song in the image, include only one to three songs from that  Format as JSON with two fields: title, artist"
    
    json_data = {
        "model": "gpt-4-vision-preview",
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": json_prompt
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": image_url
                        }
                    }
                ]
            }
        ],
        "max_tokens": 4000
    }
    
    json_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }

    json_context = ssl._create_unverified_context()
    try:
        json_connection = http.client.HTTPSConnection("api.openai.com", context=json_context)
        json_connection.request("POST", "/v1/chat/completions", json.dumps(json_data), json_headers)
        json_response = json_connection.getresponse()

        json_status = json_response.status
        json_reason = json_response.reason

        json_response_data = json.loads(json_response.read().decode("utf-8"))
        print(json_response_data)

        json_connection.close()
            
        json_message = json_response_data.get("choices")[0].get("message").get("content")
        trimmed_content = json_message.strip('```json\n').strip('\n```')
        
        print("trimmed_content")
        print(trimmed_content)
        
        return trimmed_content
        
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return None
    
@https_fn.on_request()
def make_scene_api_request(req: https_fn.Request) -> https_fn.Response:
    try:
        trigger_data = req.json
        image_url = trigger_data.get("image_url")
        
        if not image_url:
            return https_fn.Response("Image URL not provided in trigger data.")
        
        image_json = get_image_info(image_url)
        if image_json:
            json_data = json.loads(image_json)
            genre = json_data.get("genre")
            subgenre = json_data.get("subgenre")
            music = json_data.get("music")
            
            response_dict = {
                "description": json_data.get("description"),
                "playlistTitle": json_data.get("playlistTitle"),
                "music": music,
                "genre": genre,
                "subgenre": subgenre,
                "songlist": json_data.get("songlist")
            }
            
            print("response_dict")
            print(response_dict)
            
            return https_fn.Response(json.dumps(response_dict))
        else:
            return https_fn.Response("Error: No image information obtained.")
        
    except KeyError as key_error:
        return https_fn.Response(f"KeyError occurred: {str(key_error)}")

    except Exception as e:
        return https_fn.Response(f"An error occurred: {str(e)}")
