#!/usr/bin/env runhaskell
-- homework.hs
-- A simple Pandoc filter to convert Problem/Solution divs into pretty LaTeX
-- problem/solution environments

import Text.Pandoc
import Text.Pandoc.JSON

surround :: [Block] -> String -> Maybe String -> [Block]
surround blocks env args = [begin] ++ blocks ++ [end]
    where begin = RawBlock (Format "tex") ("\\begin{" ++ env ++ "}" ++ argString)
          end   = RawBlock (Format "tex") ("\\end{" ++ env ++ "}")
          argString = case args of
                        Just s  -> "{" ++ s ++ "}"
                        Nothing -> ""

homework :: Block -> [Block]
homework x@(Div (_, cls, attrs) content)
    | cls == ["Problem"]  = surround content "problem" args
    | cls == ["Solution"] = surround content "solution" Nothing
    | otherwise           = [x]
    where args = Just $ "\\problemnum" ++ src
          src = case lookup "src" attrs of
                    Just s  -> " \\,\\,(\\textsf{" ++ s ++ "})"
                    Nothing -> ""
homework x = [x]

main :: IO ()
main = toJSONFilter homework
