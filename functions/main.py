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

def createJSON(image_desc, artists):
    #json_prompt = f"Create a JSON for the following variables 1. description - required. {image_desc} 2. playlistTitle - required. a playlist title that goes with the image description. Example: 'Floating on air: A night with The Boss' 3. music - optional.  If the image contains information on a band, music artist, or song, output the band name, artist name, or song name in this field. If there isn't anything, don't include this field. 4. genre - required. Output a broad music genre that best encapsulates the vibe of the image. It should be something like pop, country, hip-hop, RNB, etc. 5. subgenre - required.  Choose a more specific and creative subgenre of the genre above that best represents the image. For example, indie pop is not specific enough. Feel free to include decades! 6. songlist - required.  Select 30 songs that fit the subgenre mentioned above. Draw inspiration from song lyrics, titles, and mood. These should be real songs from real artists that I can find on Spotify. If there was a band, music artist, or song in the image, include a few songs from that music. Here are my top artists: {artists}. If any of their songs fit the subgenre, include them.  Try to find niche songs from these artists that fit the subgenre and image description better than their most popular songs. Try to use as many top artists as possible, however, the main priority is that the songs FIT THE SUBGENRE. Do NOT include songs from these artists if they do not fit the subgenre. For example, if a top artist is Harry Styles and the subgenre is 90s country ballads, do not include Harry Styles. These should all be real songs from the artists. The songs should include a mix of popular artists and underground arists for diversity. If some of the user's top artists are included, some of the other songs should be inspired by these songs. If the artist is not in the user's top artists, do not include more than one song from an artist. All of the songs should flow together and have a similar tone. Do not include songs just so the top artist is there if the artist does not have songs that fit the subgenre. Format as JSON with three required fields: title, artist, reason (as to why it fits the subgenre and image description). So the final output should be {{ 'description': '{image_desc}', 'playlistTitle': 'Your Playlist Title', 'music': '', 'genre': 'Your Genre', 'subgenre': 'Your Subgenre', 'songlist': [{'title': 'Song Title', 'artist': 'Artist Name', 'reason': 'Reason for Selection'}] }}"
    json_prompt = f"""Create a JSON for the following variables:
    1. 'description' - required. {image_desc}
    2. 'playlistTitle' - required. A title that complements the image description. Example: 'Atmospheric Reverie: A Sonic Journey'. Make it quirky.
    3. 'music' - optional. Include details about any band, music artist, or song mentioned in the image. Omit if not relevant.
    4. 'genre' - required. Suggest a broad music genre that best represents the image's ambiance. Consider genres like pop, country, hip-hop, RNB, island, etc. Do not take into account the user's preferences.
    5. 'subgenre' - required. Choose a specific and imaginative subgenre portraying the image's mood. Incorporate diverse decades or unique styles.
    6. 'songlist' - required. Curate a list of 30 songs aligning with the specified subgenre. Utilize real songs by various artists available on Spotify. Do not prioritize a user's preferences. Only add them if they fit the genre.
    Prioritize less popular tracks from the user's top artists ({artists}) that closely match the subgenre and image description over their most popular songs.
    Encourage diversity by including both well-known and underground artists while ensuring a cohesive playlist.
    Format the output in JSON with these fields: 'title', 'artist', 'reason' (explaining the selection's fit with the subgenre and image description). Do not prioritize a user's preferences! Only add an song from their top artist if it fits the genre AND the image description AND mood. It is better to put songs not from their artists that fit vs putting a song from their top artists that doesn't fit.
    The final output should resemble this structure: {{ 'description': '{image_desc}', 'playlistTitle': 'Your Playlist Title', 'music': '', 'genre': 'Your Genre', 'subgenre': 'Your Subgenre', 'songlist': [{'title': 'Song Title', 'artist': 'Artist Name', 'reason': 'Reason for Selection'}] }}"""

    
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
            },
            {
                "role": "system",
                "content": "Please use the provided information to curate a diverse playlist that aligns with the image description and specified subgenre. Prioritize less popular songs from the user's top artists if they better fit the subgenre and image context. Aim for a well-balanced mix of both well-known and underground artists while maintaining coherence and relevance to the user's preferences."
            }
        ],
        "max_tokens": 4000
    }
    
    json_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }


def get_image_info(image_url, artists):
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
    Songlist should contain 30 songs for the image that fit the subgenre. It is very important that I get all 30 songs.  I'll pay $200 for 30 great song selections. All of the songs should fit the mood as well, so that the songs do not clash. 
    These should be real songs from real artists that I can find on Spotify. If there was a band, music artist, or song in the image, include only three song from that music. 
    Also, if applicable, include songs from my top artists: ''' + f"{artists}" + '''. 
    If any of my top artists have songs that fit the subgenre or image description, include them. Try to find niche songs from these artists that fit the subgenre and image description better than their most popular songs. 
    For example (only an example), instead of Cardigan by Taylor Swift, you might choose The Lakes or Seven if they fit the image description better. 
    Try to use as many top artists as possible, however, the main priority is that the songs FIT THE SUBGENRE. 
    Do NOT include songs from these artists if they do not fit the subgenre. These should all be real songs from the artists. 
    The soundtrack should be mostly diverse underground songs with a few mainstream songs. 
    All of the songs should flow together and have a similar tone.'''
    
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
        artists = trigger_data.get("artists")
        
        if not image_url:
            return https_fn.Response("Image URL not provided in trigger data.")
        
        image_json = get_image_info(image_url, artists)
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
            
            print("response_dict")
            print(response_dict)
            
            return https_fn.Response(json.dumps(response_dict))
        else:
            return https_fn.Response("Error: No image information obtained.")
        
    except KeyError as key_error:
        return https_fn.Response(f"KeyError occurred: {str(key_error)}")

    except Exception as e:
        return https_fn.Response(f"An error occurred: {str(e)}")
