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
For datasets without `spk_id`, we can directly mark `spk_id` as `utt_id`
```
<utt_id> <spk_id>
```
- **wav.scp**\
Format of wav.scp
```
<utt_id> <path_to_audio_file>
```
  **Note:** Make sure that you change this path when shifting your code to server

- **spk2gender** [optional file]\
Format of spk2gender file:
```
<spk_id> <gender>
```
### Creating data/local Folder
- **corpus.txt**\
This is used to train our language model (in this script SRILM with ngram order 1 is used)\
Format of text file:
```
<word1> <word2> ... <wordN>
```
### Creating data/local/dict Folder
Here, we store all the lexicon related files i.e lexicon.txt, nonsilence_phones.txt, optional_silence.txt, silence_phones.txt, extra_questions.txt (this is optional)
- **lexicon.txt**\
Format of text file:
```
<word> <phone1> <phone2> ... <phoneN>
```  
To make this file, first extract all the unique words and then run a g2p model on those words. This could be Sequitr or CMUdict. For a small dataset like this you can directly use the `word` itself instead of `<phone1> <phone2> .. <phoneN>`.

**NOTE**: Make sure to enter `!SIL SIL`  and `<UNK> SIL` rows into the lexicon.txt file.  

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

## To Run HMM-GMM Model
`./run.sh`\
**NOTE:** Make sure that you give full permissions to `run.sh`

## To Find the Scores of the Model
`./best_score.sh`\
You can find the results in `RESULTS` file.

## To Run TDNN Model
**NOTE:** This should be done in addition to HMM-GMM Model
- change `run_tdnn` variable from 0 to 1 in `run.sh`
- copy minilibrispeech local folder and place it in the current folder.
- Remove the file `local/chain/run_tdnn.sh` and copy `run_tdnn.sh` and paste it in `local/chain` folder. I have made minute changes so that it fits my directory structure etc.
- `./run.sh`

## To Find the results of This Model
- `cd exp/chain/tdnn1h_sp/decode_test && cat wer_* | ../../../../utils/best_wer.sh`
