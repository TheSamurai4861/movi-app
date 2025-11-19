#!/usr/bin/env python3
"""
Script pour appeler l'API Xtream get_series_info et sauvegarder la réponse JSON.
Utile pour analyser la structure des données d'épisodes.
"""

import json
import requests
import sys
from datetime import datetime
from urllib.parse import urlencode

# Configuration - À MODIFIER selon votre compte Xtream
ENDPOINT = "http://premium-ott.com"  # Votre endpoint Xtream
USERNAME = "dxCgZA7xKM"  # Votre username
PASSWORD = "AqtrAmfU6R"  # Votre password (à remplir)
SERIES_ID = 5172  # ID de la série One Piece

def call_xtream_api():
    """Appelle l'API Xtream get_series_info et retourne la réponse."""
    if not PASSWORD:
        print("ERREUR: Veuillez remplir le PASSWORD dans le script")
        sys.exit(1)
    
    # Construire l'URL de l'API
    params = {
        'username': USERNAME,
        'password': PASSWORD,
        'action': 'get_series_info',
        'series_id': str(SERIES_ID),
    }
    
    url = f"{ENDPOINT}/player_api.php?{urlencode(params)}"
    
    print(f"Appel de l'API Xtream...")
    print(f"URL: {url.replace(PASSWORD, '****')}")
    print(f"Série ID: {SERIES_ID}")
    print()
    
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        # Parser la réponse JSON
        data = response.json()
        
        return data
    except requests.exceptions.RequestException as e:
        print(f"Erreur lors de l'appel API: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Erreur lors du parsing JSON: {e}")
        print(f"Réponse brute: {response.text[:500]}")
        sys.exit(1)

def save_json(data, filename):
    """Sauvegarde les données JSON dans un fichier."""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"✅ JSON sauvegardé dans: {filename}")

def analyze_structure(data):
    """Analyse et affiche la structure des données."""
    print("\n" + "="*60)
    print("ANALYSE DE LA STRUCTURE")
    print("="*60)
    
    print(f"\nClés principales: {list(data.keys())}")
    
    # Analyser les épisodes
    if 'episodes' in data:
        episodes_data = data['episodes']
        print(f"\n📺 ÉPISODES:")
        print(f"  Type: {type(episodes_data).__name__}")
        
        if isinstance(episodes_data, dict):
            print(f"  Nombre de saisons: {len(episodes_data)}")
            print(f"  Clés des saisons: {list(episodes_data.keys())[:10]}...")  # Premières 10
            
            total_episodes = 0
            for season_key, season_episodes in list(episodes_data.items())[:3]:
                if isinstance(season_episodes, list):
                    print(f"\n  Saison {season_key}: {len(season_episodes)} épisodes")
                    total_episodes += len(season_episodes)
                    if season_episodes:
                        first_ep = season_episodes[0]
                        if isinstance(first_ep, dict):
                            print(f"    Clés du premier épisode: {list(first_ep.keys())}")
                            print(f"    Exemple: id={first_ep.get('id')}, episode_num={first_ep.get('episode_num')}, stream_id={first_ep.get('stream_id')}")
            
            # Compter tous les épisodes
            for season_episodes in episodes_data.values():
                if isinstance(season_episodes, list):
                    total_episodes += len(season_episodes)
            print(f"\n  Total estimé d'épisodes: {total_episodes}")
            
        elif isinstance(episodes_data, list):
            print(f"  Nombre d'épisodes dans la liste: {len(episodes_data)}")
            if episodes_data:
                first_ep = episodes_data[0]
                if isinstance(first_ep, dict):
                    print(f"  Clés du premier épisode: {list(first_ep.keys())}")
                    print(f"  Exemple premier épisode:")
                    for key in ['season', 'season_num', 'season_number', 'episode_num', 'episode', 'episode_number', 'id', 'stream_id', 'episode_id']:
                        if key in first_ep:
                            print(f"    {key}: {first_ep[key]}")
                    
                    # Analyser les saisons uniques
                    seasons = set()
                    for ep in episodes_data[:100]:  # Analyser les 100 premiers
                        if isinstance(ep, dict):
                            season = ep.get('season') or ep.get('season_num') or ep.get('season_number')
                            if season is not None:
                                seasons.add(season)
                    print(f"\n  Saisons trouvées (dans les 100 premiers): {sorted(seasons)}")
    else:
        print("\n⚠️  Clé 'episodes' non trouvée dans la réponse")
    
    # Analyser les saisons (si présentes)
    if 'seasons' in data:
        seasons_data = data['seasons']
        print(f"\n📚 SAISONS:")
        print(f"  Type: {type(seasons_data).__name__}")
        if isinstance(seasons_data, list):
            print(f"  Nombre de saisons: {len(seasons_data)}")
            if seasons_data:
                print(f"  Clés de la première saison: {list(seasons_data[0].keys()) if isinstance(seasons_data[0], dict) else 'N/A'}")
    
    # Analyser les infos (si présentes)
    if 'info' in data:
        info_data = data['info']
        print(f"\nℹ️  INFO:")
        print(f"  Type: {type(info_data).__name__}")
        if isinstance(info_data, dict):
            print(f"  Clés: {list(info_data.keys())}")

def main():
    print("="*60)
    print("DEBUG API XTREAM - get_series_info")
    print("="*60)
    print()
    
    # Appeler l'API
    data = call_xtream_api()
    
    # Générer un nom de fichier avec timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"xtream_series_{SERIES_ID}_{timestamp}.json"
    
    # Sauvegarder le JSON
    save_json(data, filename)
    
    # Analyser la structure
    analyze_structure(data)
    
    print("\n" + "="*60)
    print(f"✅ Analyse terminée. Fichier: {filename}")
    print("="*60)

if __name__ == "__main__":
    main()

