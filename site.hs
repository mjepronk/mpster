--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend, mconcat, (<>))
import           Data.List (sort)
import           Data.Functor ((<$>))
import           Hakyll

import qualified Data.ByteString.Lazy.Char8 as C
--------------------------------------------------------------------------------

main :: IO ()
main = hakyllWith siteConfig $ do
    match "static/img/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "static/pdf/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "static/js/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "static/css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "static/scss/mpster.scss" $ do
        route   $ gsubRoute "static/scss/" (const "static/css/") `composeRoutes` setExtension "css"
        compile $ scssCompiler "static/scss/"

    match "cgi-bin/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "photos/*.jpg" $ version "normal" $ do
        route $ setExtension "normal.jpg"
        compile $ getResourceLBS >>= withItemBody (unixFilterLBS "convert" [
            "jpg:-", "-resize", "1024x768", "-quality", "90", "jpg:-"])

    match "photos/*.jpg" $ version "thumbnail" $ do
        route $ setExtension "thumb.jpg"
        -- compile $ getResourceLBS >>= withItemBody (unixFilterLBS "convert" [
        --     "jpg:-", "-resize", "150x150^", "-gravity", "center", "-extent", "100x100", "-quality", "90", "jpg:-"])
        compile $ getResourceLBS >>= withItemBody (unixFilterLBS "convert" [
            "jpg:-", "-resize", "100x100^", "-gravity", "center", "-extent", "100x100", "-quality", "90", "jpg:-"])

    match "index.html" $ do
        route idRoute
        compile $ do
            -- let indexCtx =
            --         constField "title" "Home" `mappend`
            --         defaultContext
            let imagesC = (fmap.map) (flip Item ()) $ getMatches $ (.&&.) (hasVersion "normal") $ images
            let indexCtx =
                    listField "images" imageCtx imagesC `mappend`
                    constField "title" "(mes) petites dames" `mappend`
                    defaultContext
            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    create ["404.html"] $ do
        route idRoute
        compile $ do
            let notFoundCtx = (constField "title" "Niet gevonden" <> defaultContext)
            makeItem ""
                >>= loadAndApplyTemplate "templates/404.html" notFoundCtx
                >>= loadAndApplyTemplate "templates/default.html" notFoundCtx


-- Hakyll config ---------------------------------------------------------------

siteConfig :: Configuration
siteConfig = defaultConfiguration
             { deployCommand = "rsync -av _site/ www@wilkes:/srv/www/mpster.nl/" }


-- Images ----------------------------------------------------------------------

imageCtx :: Context ()
imageCtx = mconcat
    [ urlField "url"
    , urlForVersionField "normal" "normal"
    , urlForVersionField "thumbnail" "thumbnail"
    , metadataField
    , dateField "date" "%B %e, %Y"
    ]

images :: Pattern
images = fromGlob "photos/*.jpg"

urlForVersionField :: String -> String -> Context a
urlForVersionField key version = field key $
    fmap (maybe "" toUrl) . getRoute . setVersion (Just version) . itemIdentifier


-- Compilers -------------------------------------------------------------------

scssCompiler :: FilePath -> Compiler (Item String)
scssCompiler loadpath = do
  s <- getResourceString
  item <- withItemBody (unixFilter "sass"
      ["--stdin", "--scss", "--load-path", loadpath]) s
  return $ compressCss <$> item
