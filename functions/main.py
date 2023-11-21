import http.client
import json
import ssl
import time
from firebase_functions import https_fn
import requests
from google.auth.transport import requests as grequests
from google.oauth2.id_token import verify_oauth2_token

OPENAI_API_KEY =""

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
    
def generate_songs_by_genre(genre):
    prompt_songs = f"Give me a list of 20 songs by real artists that I can search up on spotify with this genre: {genre}. The songs should fit the vibe of the genre and not include the genre name in the song's title. Only include songs I can find on spotify. Format your response like this: 1... 2... 3... Do not include anything but the list. Do not make up songs"
    
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
    
@https_fn.on_request()
def make_scene_api_request(req: https_fn.Request) -> https_fn.Response:
    try:
        # Extract the URL from the trigger request's JSON data
        trigger_data = req.json
        image_url = trigger_data.get("image_url")
        
        if not image_url:
            return https_fn.Response("Image URL not provided in trigger data.")
        
        print("start")
        description = generate_desc_from_img(image_url)
        print(description)
        print("description finished")
        openai_message = make_playlist_name_api_request(description)
        print("openai_message finished")
        genre_message = generate_genre_by_mood(description)
        print("genre_message finished")
        song_message = generate_songs_by_genre(genre_message)
        print("song_message finished")
        response_json = {
            "Description": description,
            "OpenAI Message": openai_message,
            "Genre Message": genre_message,
            "Song Message": song_message
        }
        return https_fn.Response(json.dumps(response_json))
        
    except KeyError as key_error:
        return https_fn.Response(f"KeyError occurred: {str(key_error)}")

    except Exception as e:
        return https_fn.Response(f"An error occurred: {str(e)}")
