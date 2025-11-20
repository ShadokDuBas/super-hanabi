#! /usr/bin/env nu

const file = "./heroes-list.json"
const template_file = "./hero-template.json"

def get-hero-template [] {
  open $template_file
}

def get-heroes [] {
  open $file
}

def save-heroes [] {
  save -f $file
}

# Interactively ask the user to choose a value in a list
def choose [] {
  if (($in | length) <= 4) {
    $in
    | str join "\n"
    | gum choose
  } else {
    $in
    | str join "\n"
    | fzf
  }
}

# Retunrs the index of a hero
def select-hero [] {
  let printer = {
    |x| $"($x.index) ($x.item.name)"
  }
  $in
  | enumerate
  | each $printer
  | choose
  | split words
  | first
  | into int
}

# Assume the item has been stripped of its id
def hero-to-string [] {
  let h = $in
  $h
  | columns
  | each {|t|
    $h | get $t
  }
  | str join "\n\n"  
}

# Inverse of parse-string
def parse-string [
  col # The list of column names
] {
  $in
  | split row "\n\n"
  | (if ($in | length) != ($col | length) {
    return (error make --unspanned { 
      msg: "Parsing impossible, wrong number of parskips" })
    } else {$in})
  | zip $col
  | reduce --fold ({}) {|it, acc| $acc | insert $it.1 $it.0}
}

# Assume that there is no id attached to the hero
def hero-editor [] {
  let h = $in
  $h
  | hero-to-string
  | vipe
  | parse-string ($h | columns)
}

def edit-hero [] {
  let h = $in
  let id = $h.id
  let h = $h | reject id
  $h 
  | hero-editor 
  | insert id $id
}

#Add a new record to the table in $file
def "main edit" [
] {
  let heroes = get-heroes
  let index = ($heroes | select-hero)
  let modified_hero = ($heroes | get $index | edit-hero)
  $modified_hero
  | table
  | print
  | gum confirm "Save this modification?";
    if $env.LAST_EXIT_CODE != 0 {
    return "aborted modification"
  } else {
    $heroes
    | upsert $index $modified_hero
    | save-heroes
  }
}

# Add a new hero to the json file
def "main add" [
] {
  let heroes = get-heroes
  let new_hero  = (get-hero-template
  | update id ($heroes | length)
  | edit-hero)
  $new_hero
  | table
  | print
  | gum confirm "Add this hero";
    if $env.LAST_EXIT_CODE != 0 {
    return "aborted add"
  } else {
    $heroes
    | append [ $new_hero ]
    | save-heroes
  }
}

# Updates the `id` record of the table to ensure uniqueness 
def "main reindex" [
] {
  let table = get-heroes;
  $table 
  | reject id
  | merge ($table | enumerate | each {|x| {id:$x.index}}) 
  | save-heroes
}

# Functions to help with the json
# Requires gum, fzf, and vipe (moreutils) to work
# prints the table
def main [] {
  get-heroes
}
