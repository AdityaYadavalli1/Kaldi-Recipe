# Making My Own Kaldi Recipe

## Data Preparation

### data/train and data/test Folder
Here, we need to have utt2spk, text, wav.scp files.
- **text**\
Format of text file:
```
<utt_id> <word1> <word2> ... <wordN>
```  
- **utt2spk**\
Format of utt2spk file:
For small datasets we can directly mark `spk_id` as `utt_id`
```
<utt_id> <spk_id>
```
- **wav.scp**\
Format of wav.scp
```
<utt_id> <path_to_audio_file>
```
  **Note:** Make sure that you to change this path when shifting your code to server

- **spk2gender**\
Format of spk2gender file:
```
<spk_id> <gender>
```

### Creating data/local/dict Folder
Here, we store all the lexicon related files i.e lexicon.txt, nonsilence_phones.txt, optional_silence.txt, silence_phones.txt, extra_questions.txt (this is optional)
- **lexicon.txt**\
Format of text file:
```
<word> <phone1> <phone2> ... <phoneN>
```  
To make this file, first extract all the unique words and then run a g2p model on those words. This could be Sequitr or CMUdict. For a small dataset like this you can directly use the `word` itself instead of `<phone1> <phone2> .. <phoneN>`.

- **nonsilence_phones.txt**\
All unique phones in `lexicon.txt` are entered here -each in one line.

- **silence_phones.txt**\
A phone representing silence is entered (usually 'SIL') and any special noise or OOVs phones.

- **optional_silence**\
Just silence phone 'SIL' is entered in this file.


From here on, we can use various Kaldi scripts since we have got to a point where everything is formatted in a way Kaldi takes its inputs. So, the script itself will take care from here.  

## Copying from other recipes
- Copy the `local` folder from voxforge recipe
- Copy the `conf` folder from any recipe

## Making a symbolic link
- Make a symbolic link with `steps` folder in wsj recipe
- Make a symbolic link with `utils` folder in wsj recipe

**NOTE:** Change the path of KALDI_ROOT in `path.sh` to where your Kaldi is installed.

## To Run the HMM-GMM Model
`./run.sh`\
**NOTE:** Make sure that you give full permissions to `run.sh`

## To Find the scores of the Model
`./best_score.sh`\
You can find the results in `RESULTS` file.
