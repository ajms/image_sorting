from PIL import Image
import imagehash
from pathlib import Path
import json
from image_sorting.utils.core import get_project_root
import hashlib
from tqdm import tqdm
import inspect

def cache_to_json(cache_dir: Path):
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Create a unique cache filename based on function name and arguments
            func_name = func.__name__
            signature = inspect.signature(func)
            parameters = signature.parameters
            kwargs_extended = {param_name: v for param_name, v in zip(parameters.keys(), args)} | kwargs
            kwargs_str = json.dumps({k: str(v) for k, v in sorted(kwargs_extended.items())})
            print(f"{func_name=}, {kwargs_str=}")

            cache_filename = cache_dir / f"{func_name}_{hashlib.sha256(kwargs_str.encode('utf-8')).hexdigest()}.json"

            # Check if cache file exists, and if so, load data from it
            if cache_filename.exists():
                with open(cache_filename, "r") as cache_file:
                    data = json.load(cache_file)
                print(f"Cached value found: {cache_filename}")
                return data
            
            print(f"Caching: {cache_filename}")
        
            # Call the function if cache doesn't exist
            data = func(*args, **kwargs)

            # Save data to the cache file
            with open(cache_filename, "w") as cache_file:
                json.dump(data, cache_file, indent=4)
 
            return data

        return wrapper

    return decorator


@cache_to_json(cache_dir=get_project_root() / "data/processed")
def create_hash_dict(
    folder: Path, hash_function: callable = imagehash.average_hash
) -> dict[str, Path]:
    hash_dict = {}
    for fn in tqdm(folder.rglob("*")):
        # print(f"{fn.name=}")
        if not fn.is_file():
            continue
        try:
            image_hash = str(hash_function(Image.open(fn)))
        except Exception as e:
            print(f"{fn.name=}: {e=}")
            continue
        if hash_dict.get(image_hash):
            hash_dict[image_hash].append(str(fn))
        else:
            hash_dict[image_hash] = [str(fn)]
    return hash_dict

@cache_to_json(cache_dir=get_project_root() / "data/processed")
def remove_duplicates_from_hash_dict(hash_dict: dict[str, list[str]])-> dict[str, list[str]]:
    duplicates = [k for k, v in hash_dict.items() if len(v) > 1]
    delete_dict = {}
    for k in duplicates:
        delete_dict[k] = remove_duplicates(hash_dict.pop(k))
    assert len(duplicates) == len(delete_dict)
    return delete_dict

def remove_duplicates(paths: list[str]):
    max_width = 0
    max_height = 0
    tmp_picture = None
    for path in paths:
        with Image.open(path) as image:
            if image.size[0] > max_width and image.size[1] > max_height:
                max_width = image.size[0]
                max_height = image.size[1]
                tmp_picture = path
    delete_paths = list(set(paths)-set([tmp_picture]))
    assert len(delete_paths) == len(paths)-1
    return delete_paths
                

if __name__ == "__main__":
    path_to_images = input("Enter path to images: ")
    hash_dict = create_hash_dict(folder=Path(path_to_images))

    remove_duplicates_from_hash_dict(hash_dict)