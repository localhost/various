/*
 * spell-correct.go by Alex Brem <alex@freQvibez.net>
 * This is my conversion of Peter Norvig's Spelling Corrector
 * (http://www.norvig.com/spell-correct.html) to the Go language 
 */

package main

import (
	"fmt"
	"io/ioutil"
	"strings"
	"regexp"
)

type Pair struct { first, second string }
type Model struct { data map[string]int }

func NewModel() *Model {
	model := new(Model)
	return model.Init()
}

func (model *Model) Init() *Model {
	model.data = map[string]int{}
	return model
}

func (model *Model) Train(features []string) {
	for _, f := range features { model.data[f]++ }
}

func (model *Model) Edits1(word string) []string {
	const alphabet = "abcdefghijklmnopqrstuvwxyz"

	splits := []Pair{}
	for i := 0; i <= len(word); i++ {
		splits = append(splits, Pair{ word[:i], word[i:] })
	}

	set := []string{}
	for _, s := range splits {

		if len(s.second) > 0 {
			// deletes
			set = append(set, s.first + s.second[1:])

			// replaces
			for _, c := range alphabet {
				set = append(set, s.first + string(c) + s.second[1:])
			}

			// transposes
			if len(s.second) > 1 {
				set = append(set, s.first + string(s.second[1]) + string(s.second[0]) + s.second[2:])
			}

		} else {
			// deletes
			set = append(set, s.first)
		}

		// inserts
		for _, c := range alphabet {
			set = append(set, s.first + string(c) + s.second)
		}

	}

	return removeDuplicates(set)
}

func (model *Model) KnownEdits2(word string) []string {
	set := []string{}

	words := model.Edits1(word)
	for _, w := range words {
		words2 := model.Edits1(w)
		for _, w2 := range words2 {
			if _, ok := model.data[w2]; ok {
				set = append(set, w2)
			}
		}
	}

	return removeDuplicates(set)
}

func (model *Model) Known(words []string) []string {
	known := []string{}

	for _, word := range words {
		if _, ok := model.data[word]; ok {
			known = append(known, word)
		}
	}

	return known
}

func (model *Model) KnownWord(word string) []string {
	return model.Known([]string { word })
}

func (model *Model) Correct(word string) string {
	candidates := []string{}
	candidates = append(candidates, model.KnownWord(word)...)

	if len(candidates) == 0 {
		candidates = append(candidates, model.Known(model.Edits1(word))...)
	}

	if len(candidates) == 0 {
		candidates = append(candidates, model.KnownEdits2(word)...)
	}

	if len(candidates) == 0 {
		candidates = append(candidates, word)
	}

	return strings.Join(candidates, ", ")
}

func words(text []byte) []string {
	return regexp.MustCompile("[a-z]+").FindAllString(strings.ToLower(string(text)), -1)
}

func removeDuplicates(data []string) []string {
	length := len(data) - 1

	for i := 0; i < length; i++ {
		for j := i + 1; j <= length; j++ {
			if (data[i] == data[j]) {
				data[j] = data[length]
				data = data[0:length]
				length--
				j--
			}
		}
	}

	return data
}

func main() {
	data, err := ioutil.ReadFile("big.txt")
	if err != nil {
		panic("Couldn't load training data!")
	}

	model := NewModel()
	model.Train(words(data))

	fmt.Println("sumthang:", model.Correct("sumthang")) // distance: 3
	fmt.Println("somthang:", model.Correct("somthang"))
	fmt.Println("somethang:", model.Correct("somethang"))
	fmt.Println("sumethang:", model.Correct("sumethang"))
	fmt.Println("somethangs:", model.Correct("somethangs"))
	fmt.Println("foa:", model.Correct("foa"))
	fmt.Println("bar:", model.Correct("bar"))
	fmt.Println("baz:", model.Correct("baz"))
}
