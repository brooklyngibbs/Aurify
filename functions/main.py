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

def make_playlist_name_api_request(playlist_description):
    prompt = f"Give me a playlist name that fits this description: {playlist_description}"
    
    openai_data = {
        "model": "gpt-4",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7
    }

    openai_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }

    openai_context = ssl._create_unverified_context()
    openai_connection = http.client.HTTPSConnection("api.openai.com", context=openai_context)
    openai_connection.request("POST", "/v1/chat/completions", json.dumps(openai_data), openai_headers)
    openai_response = openai_connection.getresponse()

    openai_status = openai_response.status
    openai_reason = openai_response.reason

    openai_response_data = json.loads(openai_response.read().decode("utf-8"))

    openai_connection.close()

    # Extract the completion message from the OpenAI response
    openai_message = openai_response_data.get("choices")[0].get("message").get("content")
    
    openai_message = openai_message.strip('"')

    return openai_message
    
def generate_desc_from_img(image_url):
    prompt3 = "What's in this image?"
    print("start")
    desc_data = {
        "model": "gpt-4-vision-preview",
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "What’s in this image?"
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
        "max_tokens": 300
    }

    desc_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }

    desc_context = ssl._create_unverified_context()
    try:
        desc_connection = http.client.HTTPSConnection("api.openai.com", context=desc_context)
        desc_connection.request("POST", "/v1/chat/completions", json.dumps(desc_data), desc_headers)
        desc_response = desc_connection.getresponse()

        desc_status = desc_response.status
        desc_reason = desc_response.reason

        desc_response_data = json.loads(desc_response.read().decode("utf-8"))
        print(desc_response_data)

        desc_connection.close()

        # Extract the completion message from the OpenAI response
        desc_message = desc_response_data.get("choices")[0].get("message").get("content")
        return desc_message
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return None

    
    
def generate_genre_by_mood(playlist_description):
    prompt2 = f"generate a broad music genre for this image description: {playlist_description}"

    genre_data = {
        "model": "gpt-4",
        "messages": [{"role": "user", "content": prompt2}],
        "temperature": 0.8
    }

    genre_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }

    genre_context = ssl._create_unverified_context()
    genre_connection = http.client.HTTPSConnection("api.openai.com", context=genre_context)
    genre_connection.request("POST", "/v1/chat/completions", json.dumps(genre_data), genre_headers)
    genre_response = genre_connection.getresponse()

    genre_status = genre_response.status
    genre_reason = genre_response.reason

    genre_response_data = json.loads(genre_response.read().decode("utf-8"))

    genre_connection.close()

    # Extract the completion message from the OpenAI response
    genre_message = genre_response_data.get("choices")[0].get("message").get("content")
    

    return genre_message
    
def generate_songs_by_genre(genre, subgenre, music):
    prompt_songs_null = f"Give me a list of 40 songs by real artists that I can search up on spotify with this genre: {genre} and this subgenre: {subgenre}. The songs should fit the vibe of the genre and not include the genre name in the song's title. Only include songs I can find on spotify. Format your response like this: 1... 2... 3... Do not include anything but the list. Do not make up songs"
    
    prompt_songs_music = f"Give me a list of 40 songs by real artists that I can search up on spotify with this genre: {genre} and this subgenre: {subgenre}. Be sure to include at least one song from {music}. The songs should fit the vibe of the genre and not include the genre name in the song's title. Only include songs I can find on spotify. Format your response like this: 1... 2... 3... Do not include anything but the list. Do not make up songs"
    
    if music != None:
        prompt_songs = prompt_songs_music
    else:
        prompt_songs = prompt_songs_null
    
    songs_data = {
        "model": "gpt-4",
        "messages": [{"role": "user", "content": prompt_songs}],
        "temperature": 0.8,
        "max_tokens": 1000
    }

    songs_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }
    
    songs_context = ssl._create_unverified_context()
    songs_connection = http.client.HTTPSConnection("api.openai.com", context=songs_context)
    songs_connection.request("POST", "/v1/chat/completions", json.dumps(songs_data), songs_headers)
    songs_response = songs_connection.getresponse()

    songs_status = songs_response.status
    songs_reason = songs_response.reason

    songs_response_data = json.loads(songs_response.read().decode("utf-8"))

    songs_connection.close()

    # Extract the completion message from the OpenAI response
    songs_message = songs_response_data.get("choices")[0].get("message").get("content")

    return songs_message
    
def get_image_info(image_url):
    json_prompt = "Analyze the image and output information as a json object with the following fields: 1. description - required. containins a description of what is in the image 2. playlistTitle - required. a playlist title that goes with the image description.  Example: \"Floating on air: A night with The Boss\" or \"Chilled vibes with a tech savy tabby\" 3. music - optional.  If the image contains information on a band, music artist, or song, output the band name, artist name, or song name in this field. If there isn't anything, don't include this field. 4. genre - required. Output a broad music genre that best encapsulates the vibe of the image. 5. subgenre - required.  Choose a more specific subgenre of the genre above that best represents the image. Be creative! 6. songlist - required.  Select 40 songs that fit the genre and subgenre mentioned above.  The songs should not mention the name of the genre or subgenre.  These should be real songs from real artists that I can find on Spotify. If there was a band, music artist, or song in the image, include only one to three songs from that  Format as JSON with two fields: title, artist."
    
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
