#!/usr/bin/env python3
"""
Script pour mapper les épisodes TMDB avec les épisodes Xtream pour One Piece.
Applique la même logique de détection globale/relative et de conversion que le code Dart.
"""

import json
import requests
from datetime import datetime
from urllib.parse import urlencode
from typing import Dict, List, Tuple, Optional

# Configuration
TMDB_API_KEY = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0ZjliZDI0YzhiMjYyNWUyMzk2ZTNlZjg2YTg5ZmU0YyIsIm5iZiI6MTY0ODM4MzU1My4yNDEsInN1YiI6IjYyNDA1NjQxYzc0MGQ5MDA0N2EzNmNjMyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.KvWRTSdQiWBF2-KQhgN_7xzSJS8AS7xE3-A7fzxCno8"  # À remplir si nécessaire
TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_SERIES_ID = 37854  # One Piece

XTREAM_ENDPOINT = "http://premium-ott.com"
XTREAM_USERNAME = "dxCgZA7xKM"
XTREAM_PASSWORD = "AqtrAmfU6R"
XTREAM_SERIES_ID = 5172  # One Piece

def get_tmdb_seasons():
    """Récupère toutes les saisons et épisodes depuis TMDB."""
    print("Récupération des données TMDB...")
    
    # Préparer les headers avec l'API key
    headers = {}
    if TMDB_API_KEY:
        headers["Authorization"] = f"Bearer {TMDB_API_KEY}"
        headers["accept"] = "application/json"
    
    # Récupérer les détails de la série
    url = f"{TMDB_BASE_URL}/tv/{TMDB_SERIES_ID}"
    
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        series_data = response.json()
        
        seasons_data = []
        for season_info in series_data.get("seasons", []):
            season_number = season_info.get("season_number")
            if season_number is None:
                continue
            
            # Récupérer les détails de la saison
            season_url = f"{TMDB_BASE_URL}/tv/{TMDB_SERIES_ID}/season/{season_number}"
            season_response = requests.get(season_url, headers=headers, timeout=30)
            season_response.raise_for_status()
            season_detail = season_response.json()
            
            episodes = []
            for ep in season_detail.get("episodes", []):
                episodes.append({
                    "episode_number": ep.get("episode_number"),
                    "name": ep.get("name"),
                    "id": ep.get("id"),
                })
            
            seasons_data.append({
                "season_number": season_number,
                "episode_count": season_info.get("episode_count", 0),
                "episodes": episodes,
            })
            
            print(f"  Saison {season_number}: {len(episodes)} épisodes")
        
        return seasons_data
    except Exception as e:
        print(f"Erreur lors de la récupération TMDB: {e}")
        return []

def get_xtream_episodes():
    """Récupère tous les épisodes depuis Xtream."""
    print("\nRécupération des données Xtream...")
    
    params = {
        'username': XTREAM_USERNAME,
        'password': XTREAM_PASSWORD,
        'action': 'get_series_info',
        'series_id': str(XTREAM_SERIES_ID),
    }
    
    url = f"{XTREAM_ENDPOINT}/player_api.php?{urlencode(params)}"
    
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        data = response.json()
        
        episodes_data = data.get('episodes', [])
        if not episodes_data:
            print("  Aucun épisode trouvé dans la réponse Xtream")
            return {}
        
        # Parser selon la structure (List<List<Map>> ou List<Map>)
        xtream_episodes = {}  # {season: {episode_num: {id, extension}}}
        
        if isinstance(episodes_data, list) and episodes_data:
            if isinstance(episodes_data[0], list):
                # Structure: List<List<Map>> - chaque sous-liste est une saison
                print(f"  Structure détectée: List<List<Map>> - {len(episodes_data)} saisons")
                for season_list in episodes_data:
                    if isinstance(season_list, list):
                        for episode_data in season_list:
                            if isinstance(episode_data, dict):
                                season_num = episode_data.get('season') or episode_data.get('season_num') or episode_data.get('season_number')
                                episode_num = episode_data.get('episode_num') or episode_data.get('episode') or episode_data.get('episode_number')
                                episode_id = episode_data.get('id') or episode_data.get('stream_id') or episode_data.get('episode_id')
                                extension = episode_data.get('container_extension') or episode_data.get('extension')
                                
                                if season_num is not None and episode_num is not None and episode_id is not None:
                                    season_num = int(season_num) if isinstance(season_num, (int, str)) and str(season_num).isdigit() else None
                                    episode_num = int(episode_num) if isinstance(episode_num, (int, str)) and str(episode_num).isdigit() else None
                                    episode_id = int(episode_id) if isinstance(episode_id, (int, str)) and str(episode_id).isdigit() else None
                                    
                                    if season_num is not None and episode_num is not None and episode_id is not None:
                                        if season_num not in xtream_episodes:
                                            xtream_episodes[season_num] = {}
                                        xtream_episodes[season_num][episode_num] = {
                                            "id": episode_id,
                                            "extension": extension,
                                        }
            else:
                # Structure: List<Map> - liste plate d'épisodes
                print(f"  Structure détectée: List<Map> - {len(episodes_data)} épisodes")
                for episode_data in episodes_data:
                    if isinstance(episode_data, dict):
                        season_num = episode_data.get('season') or episode_data.get('season_num') or episode_data.get('season_number')
                        episode_num = episode_data.get('episode_num') or episode_data.get('episode') or episode_data.get('episode_number')
                        episode_id = episode_data.get('id') or episode_data.get('stream_id') or episode_data.get('episode_id')
                        extension = episode_data.get('container_extension') or episode_data.get('extension')
                        
                        if season_num is not None and episode_num is not None and episode_id is not None:
                            season_num = int(season_num) if isinstance(season_num, (int, str)) and str(season_num).isdigit() else None
                            episode_num = int(episode_num) if isinstance(episode_num, (int, str)) and str(episode_num).isdigit() else None
                            episode_id = int(episode_id) if isinstance(episode_id, (int, str)) and str(episode_id).isdigit() else None
                            
                            if season_num is not None and episode_num is not None and episode_id is not None:
                                if season_num not in xtream_episodes:
                                    xtream_episodes[season_num] = {}
                                xtream_episodes[season_num][episode_num] = {
                                    "id": episode_id,
                                    "extension": extension,
                                }
        
        total_episodes = sum(len(episodes) for episodes in xtream_episodes.values())
        print(f"  Total: {len(xtream_episodes)} saisons, {total_episodes} épisodes parsés")
        
        return xtream_episodes
    except Exception as e:
        print(f"Erreur lors de la récupération Xtream: {e}")
        return {}

def is_season_using_global_numbering(season_number: int, tmdb_seasons: List[Dict]) -> bool:
    """Détecte si une saison utilise la numérotation globale ou relative."""
    season = next((s for s in tmdb_seasons if s["season_number"] == season_number), None)
    if not season or not season.get("episodes"):
        return False
    
    episodes = season["episodes"]
    if not episodes:
        return False
    
    first_episode_number = episodes[0].get("episode_number", 0)
    if first_episode_number > 1:
        return True
    
    last_episode_number = episodes[-1].get("episode_number", 0)
    if last_episode_number > len(episodes):
        return True
    
    return False

def convert_tmdb_episode_to_xtream(
    tmdb_episode_number: int,
    season_number: int,
    tmdb_seasons: List[Dict]
) -> int:
    """Convertit le numéro d'épisode TMDB en numéro relatif à la saison pour Xtream."""
    is_global = is_season_using_global_numbering(season_number, tmdb_seasons)
    
    if not is_global:
        return tmdb_episode_number
    
    # Calculer le nombre total d'épisodes dans toutes les saisons précédentes
    # IMPORTANT: Exclure la saison 0 car elle n'existe pas dans Xtream
    total_episodes_before = 0
    for season in tmdb_seasons:
        # Ignorer la saison 0 (épisodes spéciaux qui n'existent pas dans Xtream)
        if season["season_number"] > 0 and season["season_number"] < season_number:
            total_episodes_before += len(season.get("episodes", []))
    
    xtream_episode_number = tmdb_episode_number - total_episodes_before
    return xtream_episode_number if xtream_episode_number > 0 else 1

def map_episodes(tmdb_seasons: List[Dict], xtream_episodes: Dict[int, Dict[int, Dict]]):
    """Mappe les épisodes TMDB avec les épisodes Xtream."""
    print("\nMapping des épisodes...")
    
    mapping_results = []
    
    for tmdb_season in tmdb_seasons:
        season_number = tmdb_season["season_number"]
        tmdb_episodes = tmdb_season.get("episodes", [])
        
        is_global = is_season_using_global_numbering(season_number, tmdb_seasons)
        
        season_results = {
            "season_number": season_number,
            "is_global_numbering": is_global,
            "tmdb_episode_count": len(tmdb_episodes),
            "xtream_episode_count": len(xtream_episodes.get(season_number, {})),
            "episodes": [],
        }
        
        for tmdb_ep in tmdb_episodes:
            tmdb_ep_num = tmdb_ep.get("episode_number")
            if tmdb_ep_num is None:
                continue
            
            # Convertir le numéro d'épisode TMDB en numéro Xtream
            xtream_ep_num = convert_tmdb_episode_to_xtream(
                tmdb_ep_num,
                season_number,
                tmdb_seasons
            )
            
            # Chercher l'épisode correspondant dans Xtream
            xtream_ep_data = None
            if season_number in xtream_episodes:
                xtream_ep_data = xtream_episodes[season_number].get(xtream_ep_num)
            
            episode_mapping = {
                "tmdb_episode_number": tmdb_ep_num,
                "tmdb_episode_name": tmdb_ep.get("name", ""),
                "tmdb_episode_id": tmdb_ep.get("id"),
                "xtream_episode_number": xtream_ep_num,
                "xtream_found": xtream_ep_data is not None,
                "xtream_episode_id": xtream_ep_data.get("id") if xtream_ep_data else None,
                "xtream_extension": xtream_ep_data.get("extension") if xtream_ep_data else None,
                "conversion_applied": is_global and tmdb_ep_num != xtream_ep_num,
            }
            
            season_results["episodes"].append(episode_mapping)
        
        mapping_results.append(season_results)
        
        # Statistiques pour cette saison
        found_count = sum(1 for ep in season_results["episodes"] if ep["xtream_found"])
        print(f"  Saison {season_number}: {found_count}/{len(season_results['episodes'])} épisodes mappés (global={is_global})")
    
    return mapping_results

def main():
    print("=" * 80)
    print("MAPPING ÉPISODES TMDB <-> XTREAM - ONE PIECE")
    print("=" * 80)
    print()
    
    # Récupérer les données
    tmdb_seasons = get_tmdb_seasons()
    xtream_episodes = get_xtream_episodes()
    
    if not tmdb_seasons:
        print("Erreur: Impossible de récupérer les données TMDB")
        return
    
    if not xtream_episodes:
        print("Erreur: Impossible de récupérer les données Xtream")
        return
    
    # Mapper les épisodes
    mapping_results = map_episodes(tmdb_seasons, xtream_episodes)
    
    # Générer le rapport
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"tmdb_xtream_mapping_{timestamp}.json"
    
    report = {
        "tmdb_series_id": TMDB_SERIES_ID,
        "xtream_series_id": XTREAM_SERIES_ID,
        "timestamp": timestamp,
        "tmdb_seasons_count": len(tmdb_seasons),
        "xtream_seasons_count": len(xtream_episodes),
        "mapping_results": mapping_results,
    }
    
    # Sauvegarder le rapport
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Rapport sauvegardé dans: {filename}")
    
    # Afficher un résumé
    total_tmdb = sum(len(s["episodes"]) for s in mapping_results)
    total_mapped = sum(
        sum(1 for ep in s["episodes"] if ep["xtream_found"])
        for s in mapping_results
    )
    
    print(f"\nRésumé:")
    print(f"  Total épisodes TMDB: {total_tmdb}")
    print(f"  Total épisodes mappés: {total_mapped} ({total_mapped/total_tmdb*100:.1f}%)")
    
    # Afficher les saisons avec problèmes
    print(f"\nSaisons avec problèmes:")
    for season_result in mapping_results:
        found_count = sum(1 for ep in season_result["episodes"] if ep["xtream_found"])
        if found_count < len(season_result["episodes"]):
            missing = len(season_result["episodes"]) - found_count
            print(f"  Saison {season_result['season_number']}: {missing} épisodes non mappés")

if __name__ == "__main__":
    main()

