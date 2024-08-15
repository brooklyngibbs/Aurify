import http.client
import json
import ssl
import time
import os
from firebase_functions import https_fn
import requests
from google.auth.transport import requests as grequests
from google.oauth2.id_token import verify_oauth2_token
from firebase_admin import messaging
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import random
import uuid
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Initialize Firebase Admin SDK
cred = credentials.ApplicationDefault()
firebase_admin.initialize_app(cred)

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

genres = {
    "acoustic", "afrobeat", "alt-rock", "alternative", "ambient", "anime", "black-metal", "bluegrass", "blues",
    "bossanova", "brazil", "breakbeat", "british", "cantopop", "chicago-house", "children", "chill", "classical",
    "club", "comedy", "country", "dance", "dancehall", "death-metal", "deep-house", "detroit-techno", "disco",
    "disney", "drum-and-bass", "dub", "dubstep", "edm", "electro", "electronic", "emo", "folk", "forro", "french",
    "funk", "garage", "german", "gospel", "goth", "grindcore", "groove", "grunge", "guitar", "happy", "hard-rock",
    "hardcore", "hardstyle", "heavy-metal", "hip-hop", "holidays", "honky-tonk", "house", "idm", "indian", "indie",
    "indie-pop", "industrial", "iranian", "j-dance", "j-idol", "j-pop", "j-rock", "jazz", "k-pop", "kids", "latin",
    "latino", "malay", "mandopop", "metal", "metal-misc", "metalcore", "minimal-techno", "movies", "mpb", "new-age",
    "new-release", "opera", "pagode", "party", "philippines-opm", "piano", "pop", "pop-film", "post-dubstep",
    "power-pop", "progressive-house", "psych-rock", "punk", "punk-rock", "r-n-b", "rainy-day", "reggae", "reggaeton",
    "road-trip", "rock", "rock-n-roll", "rockabilly", "romance", "sad", "salsa", "samba", "sertanejo", "show-tunes",
    "singer-songwriter", "ska", "sleep", "songwriter", "soul", "soundtracks", "spanish", "study", "summer", "swedish",
    "synth-pop", "tango", "techno", "trance", "trip-hop", "turkish", "work-out", "world-music"
}

def get_image_info(image_url):
    json_prompt = '''Analyze the image and output information as a valid json object (only include the JSON) with the following fields:
    {
      "description": "contains a detailed description of what is in the image including prominent colors, vibes and emotions provoked. describe the image as if it's a magazine collage or pinterest board",
      "playlistTitle": "Generate a trendy, Gen Z style playlist title that fits the image description. The title should be creative, evocative, witty, and similar to these examples: \"my coming of age movie\", \"clean girl. journaling. gym. 6 am. lexapro era.\", \"dirty martini. extra dirty. three olives 🫒\", \"that one night you felt infinite\", \"*disco man emoji*\", \"a dystopian training montage\", \"oldest daughter syndrome\", \"the feeling that something bad will happen\", \"driving to the grand canyon, windows down, sun out\", \"tumblr. doc martens. taylor swift and uhhhhh the 1975\", \"songs where you HAVE to shout 1 2 3 4\", \"dancing with the love of my life in an empty laundromat\", \"cue my dirty little secret\", \"pov: it’s summer 2015\", \"one more drink\". Avoid traditional or generic titles. Be creative and funny with your words, format, visuals, etc! Be trendy and with the times.",
      "music": "optional - If the image contains information on a band, music artist, or song, output the band name, artist name, or song name in this field. If there isn't anything, don't include this field.",
      "genre": "Output a broad music genre that best encapsulates the vibe of the image out of these options only - {genres} ",
      "mood": "the general mood of the playlist ex. upbeat, sad, thought-provoking, cozy, etc.",
      "subgenre": "Choose a second genre to go with the first genre for a more specific vibe. Choose from this list {genres} ",
      "artist": "Choose an artist that best encapsulate the chosen genre and subgenre together, as well as fit the image description and soundtrack for this image. Remember, we are creating the perfect soundtrack for the image and image description.",
      "target_danceability": "number from 0-1 to represent target danceability for all of the songs in the soundtrack",
      "target_energy": "number from 0-1 to represent target energy for all of the songs in the soundtrack",
      "songlist": [
        {"title": "The title of the song",
         "artist": "The artist of the song",
         "reason": "The reason the song was selected"
        }
      ]
    }
    Songlist should contain 5 songs for the image that fit the subgenre. It is very important that I get all 30 songs.  I'll pay $200 for 5 great song selections. All of the songs should fit the mood as well, so that the songs do not clash.
    These should be real songs from real artists that I can find on Spotify. If there was a band, music artist, or song in the image, include only three song from that music.
    The soundtrack should be 30 songs total: twenty of underground, less popular artists, twenty should be more mainstream artists and songs. Make sure to mix them together. Prioritize songs that fit the subgenre and image description rather than popular songs.
    All of the songs should flow together and have a similar tone. Only use one song from each artist you choose. Make sure to choose the song that best fits the subgenre and image description from their entire discogrpahy. Ensure the JSON output adheres to the following structure:

    {
    "description": "",
    "playlistTitle": "",
    "music": "",
    "genre": "",
    "subgenre": "",
    "mood": "",
    "artist": "",
    "target_danceability": "",
    "target_energy": "",
    "songlist": [
        {
        "title": "",
        "artist": "",
        "reason": ""
        },
    ]
    }
    '''

    json_data = {
        "model": "gpt-4o",
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
            description = json_data.get("description")
            playlistTitle = json_data.get("playlistTitle")
            genre = json_data.get("genre")
            subgenre = json_data.get("subgenre")
            music = json_data.get("music")
            mood = json_data.get("mood")
            artist = json_data.get("artist")
            target_danceability = json_data.get("target_danceability")
            target_energy = json_data.get("target_energy")
            songlist = json_data.get("songlist")

            response_dict = {
                "description": description,
                "playlistTitle": playlistTitle,
                "music": music,
                "genre": genre,
                "subgenre": subgenre,
                "mood": mood,
                #"artist": artist,
                #"target_danceability": target_danceability,
                #"target_energy": target_energy,
                "songlist": songlist
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
            description = json_data.get("description")
            playlistTitle = json_data.get("playlistTitle")
            genre = json_data.get("genre")
            subgenre = json_data.get("subgenre")
            music = json_data.get("music")
            mood = json_data.get("mood")
            artist = json_data.get("artist")
            target_danceability = json_data.get("target_danceability")
            target_energy = json_data.get("target_energy")
            songlist = json_data.get("songlist")

            response_dict = {
                "description": description,
                "playlistTitle": playlistTitle,
                "music": music,
                "genre": genre,
                "subgenre": subgenre,
                "mood": mood,
                #"artist": artist,
                #"target_danceability": target_danceability,
                #"target_energy": target_energy,
                "songlist": songlist
            }

            return https_fn.Response(json.dumps(response_dict))
        else:
            return https_fn.Response("Error: No image information obtained.")

    except KeyError as key_error:
        return https_fn.Response(f"KeyError occurred: {str(key_error)}")

    except Exception as e:
        return https_fn.Response(f"An error occurred: {str(e)}")


def send_daily_theme_notification():
    db = firebase_admin.firestore.client()

    # Get the themes document reference
    themes_ref = db.collection('themes').document('themes')

    # Get the themes data
    themes_data = themes_ref.get().to_dict()

    themes_count = len(themes_data.keys())
    if themes_count <= 10:
        send_email(
            "Low Theme Count Alert",
            "There are 10 or fewer themes left in the themes/themes collection."
        )
        print("Low theme count email alert sent.")
    else:
        print(f"Theme count is sufficient: {themes_count}")

    if not themes_data:
        print('No themes found in "themes/themes". Checking "themes/old"...')
        old_themes_ref = db.collection('themes').document('old')
        old_themes_data = old_themes_ref.get().to_dict()
        if old_themes_data:
            themes_data = old_themes_data
            print('Themes found in "themes/old".')
        else:
            print('No themes found in "themes/old".')
            return

    # Get the list of themes
    themes = list(themes_data.keys())
    random.shuffle(themes)

    if not themes:
        print('No themes found.')
        return

    # Get a random theme
    theme_id = themes[0]
    theme_text = themes_data[theme_id]

    # Define the notification message with the theme's title and body
    message = messaging.Message(
        notification=messaging.Notification(
            title="Check out today's daily theme!",
            body=f"Upload a picture {theme_text}"
        ),
        topic="dailyTheme"
    )

    # Send the message
    response = messaging.send(message)
    print("Successfully sent message:", response)

    # Move the theme to themes/old only if it's from themes/themes
    if 'themes/themes' in themes_ref.path:
        move_theme_to_old(theme_id)
    return


def move_theme_to_old(theme_id):
    # Get a Firestore client
    db = firebase_admin.firestore.client()

    # Get references to the themes document and the old themes document
    themes_ref = db.collection('themes').document('themes')
    old_themes_ref = db.collection('themes').document('old')

    # Start a batch to perform multiple operations atomically
    batch = db.batch()

    try:
        # Get the current themes document
        themes_doc = themes_ref.get()
        if themes_doc.exists:
            themes_data = themes_doc.to_dict()

            # Check if the theme exists in the current themes
            if theme_id in themes_data:
                theme_text = themes_data[theme_id]

                # Create a unique key for the old theme using a UUID
                old_theme_key = f"{theme_id}_{uuid.uuid4().hex}"

                # Add the theme to the old themes document under the unique key
                batch.update(old_themes_ref, {old_theme_key: theme_text})

                # Remove the theme from the current themes document
                batch.update(themes_ref, {theme_id: firestore.DELETE_FIELD})

                # Commit the batch
                batch.commit()
                print(f"Moved theme {theme_id} to old themes.")
            else:
                print(f"Theme {theme_id} not found.")
        else:
            print("Themes document does not exist.")
    except Exception as e:
        print(f"An error occurred while moving theme {theme_id}: {e}")

    return


def send_email(subject, body):
    db = firebase_admin.firestore.client()
    config_ref = db.collection('config').document('emailConfig')
    config = config_ref.get().to_dict()

    if config:
        sender_email = config.get('emailAddress')
        password = config.get('emailPassword')
        receiver_email = "aurifyapp@gmail.com"

        message = MIMEMultipart()
        message["From"] = sender_email
        message["To"] = receiver_email
        message["Subject"] = subject

        message.attach(MIMEText(body, "plain"))

        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            server.login(sender_email, password)
            server.sendmail(sender_email, receiver_email, message.as_string())
            print("Email sent to aurifyapp@gmail.com")
    else:
        print("Email configuration not found in Firestore.")


@https_fn.on_request(timeout_sec=120)
def scheduled_push_notification(req: https_fn.Request) -> https_fn.Response:
    send_daily_theme_notification()
    return https_fn.Response("Push notification sent")
