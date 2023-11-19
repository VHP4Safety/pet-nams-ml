FLAGS <- flags(
  flag_numeric("dropout1", 0.5),
  flag_numeric("dropout2", 0.5),
  flag_integer("units1", 512),
  flag_integer("units2", 64)
)

batches <- 50

## -------------------------------------------------------------------------------------------------
library(tensorflow)
library(tidyverse)
library(keras)


## -------------------------------------------------------------------------------------------------
substances <- read_csv(
  here::here(
    "data-raw",
    "substances.csv")) |>
  janitor::clean_names()

acute_data <- read_csv(
    here::here(
      "data-raw",
      "acute_tox_data.csv")) |>
  janitor::clean_names()



## -------------------------------------------------------------------------------------------------
ind <- duplicated(substances$qsar_ready_smiles)
sum(ind)

substances[ind,] -> x
acute_data[ind,] -> y

y |> group_by(nontoxic) |> tally()

## we remove the duplicates
substances <- substances[!ind, ]
acute_data <- acute_data[!ind, ]


## -------------------------------------------------------------------------------------------------
acute_data_select <- acute_data |>
  dplyr::select(
    dtxsid,
    nontoxic,
    ld50_lm
  )

substances_select <- substances |>
  dplyr::select(
    dtxsid,
    qsar_ready_smiles
  )

data_nn <- full_join(acute_data_select, substances_select)


## -------------------------------------------------------------------------------------------------
library(rcdk)
library(rcdklibs)
all_smiles <- substances_select$qsar_ready_smiles
all_mols <-parse.smiles(all_smiles)
all_mols[[1]]


## -------------------------------------------------------------------------------------------------
all.fp <-
  map(all_mols,
      get.fingerprint,
      type='standard')

## Convert the pf list to a df
fp_tbl <- fingerprint::fp.to.matrix(all.fp) |> as_tibble()
## adding the predicted class (nontoxic as column)

fp_tbl <- fp_tbl |>
  mutate(
    class = ifelse(
      test = acute_data_select$nontoxic == "TRUE",  ## recode the class, 0 = nontoxic, 1 = toxic
      yes = 0,
      no = 1),
    ld50_lm = acute_data_select$ld50_lm) |>
  relocate(class, ld50_lm)



## -------------------------------------------------------------------------------------------------
library(rsample)

## seed for reproducibility
set.seed(123)
data_split <- initial_split(fp_tbl, prop = 3/4)

## trainig data
training_data <- training(data_split) |>
  select(-c(class, ld50_lm)) |>
  as.matrix() |>
  array_reshape(c(nrow(training(data_split)), 1*1024))

training_labels_class <- training(data_split) |> select(class) |>
  as.matrix() |>
#  as.integer() |>
  array_reshape(nrow(training(data_split)))

## test data
test_data <- testing(data_split) |>
  select(-c(class, ld50_lm)) |>
  as.matrix() |>
  array_reshape(c(nrow(testing(data_split)), 1*1024))

test_labels_class <- testing(data_split) |> select(class) |>
  as.matrix() |>
# as.integer() |>
  array_reshape(nrow(testing(data_split)))

training_data[1,c(1:80)]
training_labels_class[1:10]
test_data[1,c(1:80)]
test_labels_class[1:10]




## -------------------------------------------------------------------------------------------------
set.seed(123)
## simpler models
model <- keras_model_sequential(input_shape = c(1*1024)) |>
  layer_dense(units = FLAGS$units1, activation = "relu") %>%
  layer_dropout(rate = FLAGS$dropout1) |>
  layer_dense(units = FLAGS$units2, activation = "relu") %>%
  layer_dropout(rate = FLAGS$dropout2) |>
  layer_dense(units = 1, activation = "sigmoid")

model %>% compile(
  optimizer = "rmsprop",
  loss = "binary_crossentropy",
  metrics = "accuracy"
)

## store training in a history object so that we can see how the model is doing, also on a small validation set.
## validation split, means that 20% of the training data is reserved for validation.
history <- model %>%
  fit(training_data,
      training_labels_class,
      epochs = 20,
      # Suppress logging.
      verbose = 2,
  # Calculate validation results on 20% of the training data.
  validation_split = 0.2
)

## we can plot the history
plot(history)

## evaluate our model on thetest data
model %>% evaluate(test_data, test_labels_class, verbose = 2) -> eval_metrics

# Confusion matrix
pred <- model %>% predict(test_data, batch_size = batches)
y_pred = round(pred)
confusion_matrix = table(y_pred, test_labels_class)
confusion_matrix

# Output metrics
cat('Test loss:', eval_metrics[[1]], '\n')
cat('Test accuracy:', eval_metrics[[2]], '\n')
