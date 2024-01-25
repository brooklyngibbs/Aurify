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
    json_prompt = '''Analyze the image and output information as a valid json object (and only the JSON) with the following fields:
    {
      "description": "containins a detailed description of what is in the image including prominent colors and vibes and emotions provoked",
      "playlistTitle": "a playlist title that goes with the image description. Example: \"Floating on air: A night with The Boss\"",
      "music": "optional - If the image contains information on a band, music artist, or song, output the band name, artist name, or song name in this field. If there isn't anything, don't include this field.",
      "genre": "Output a broad music genre that best encapsulates the vibe of the image. It should be something like pop, country, hip-hop, RNB, etc.",
      "subgenre": "Choose a more specific and creative subgenre of the genre above that best represents the image. For example, indie pop is not specific enough. Feel free to include decades!",
      "mood": "the general mood of the playlist ex. upbeat, sad, thought-provoking, cozy, etc.",
      "songlist": [
        {"title": "The title of the song",
         "artist": "The artist of the song",
         "reason": "The reason the song was selected"
        }
      ]
    }
    Songlist should contain 40 songs for the image that fit the subgenre. It is very important that I get all 40 songs.  I'll pay $200 for 40 great song selections. All of the songs should fit the mood as well, so that the songs do not clash.
    These should be real songs from real artists that I can find on Spotify. If there was a band, music artist, or song in the image, include only three song from that music.
    The soundtrack should be 40 songs total: twenty of underground, less popular artists, twenty should be more mainstream artists and songs. Make sure to mix them together. Prioritize songs that fit the subgenre and image description rather than popular songs.
    All of the songs should flow together and have a similar tone. Only use one song from each artist you choose. Make sure to choose the song that best fits the subgenre and image description from their entire discogrpahy. Do not include anything but the JSON. '''
    
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
        
        print(trimmed_content)
        
        return trimmed_content
        
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return None
    
@https_fn.on_call(
    enforce_app_check=True  # Reject requests with missing or invalid App Check tokens.
)
def make_scene_api_request(data, context) -> dict:
    try:
        trigger_data = data.get("data")
        image_url = trigger_data.get("image_url")

        if not image_url:
            return {"error": "Image URL not provided in trigger data."}

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
                "mood": json_data.get("mood"),
                "songlist": json_data.get("songlist")
            }

            return response_dict
        else:
            return {"error": "No image information obtained."}

    except KeyError as key_error:
        return {"error": f"KeyError occurred: {str(key_error)}"}

    except Exception as e:
        return {"error": f"An error occurred: {str(e)}"}
        
@https_fn.on_request(timeout_sec=120)
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
                "mood": json_data.get("mood"),
                "songlist": json_data.get("songlist")
            }
            
            return https_fn.Response(json.dumps(response_dict))
        else:
            return https_fn.Response("Error: No image information obtained.")
        
    except KeyError as key_error:
        return https_fn.Response(f"KeyError occurred: {str(key_error)}")

    except Exception as e:
        return https_fn.Response(f"An error occurred: {str(e)}")
