---
title: "Ejemplo de periodismo de datos con R"
author: "Isaac Gonzalez - www.datascience4business.com"
output:
  #html_document:
  #  df_print: paged
 # pdf_document: default
editor_options:
  chunk_output_type: console
---

# 1. PREPARACION DEL ANALISIS

El objetivo es aportar información rigurosa sobre el debate en cuanto al nivel impositivo de España:

* Analizando la presión fiscal (impuestos recaudados sobre el PIB)
* Analizando el esfuerzo fiscal (nivel de esfuerzo del contribuyente teniendo en cuenta su poder adquisitivo)
* En qué se invierte el dinero recaudado

```{r, include = FALSE}
#Instalar el paquete (solo la primera vez)
#install.packages('tesseract')
#install.packages('tidyverse')
#install.packages('janitor')

#Descargar el motor de español (solo la primera vez)
#tesseract_download("spa")
```

```{r, include = FALSE}
library(tesseract)
library(tidyverse)
library(janitor)
```


# 2. ANALISIS DE LA PRESION Y ESFUERZO FISCAL

Fuente de los datos: https://www.elblogsalmon.com/indicadores-y-estadisticas/impuestos-esfuerzo-fiscal-espanoles-desmedido

Se ha utilizado tecnología OCR sobre la fuente citada para extraer los datos de la imagen y poder utilizarlos en los análisis.

```{r, include = FALSE}
motor <- tesseract('spa')

ruta_imagen <- 'https://i.blogs.es/c03a1d/screenshot_20200824-024453_chrome/1366_2000.jpg'

tabla <- ocr(ruta_imagen, engine = motor)
```

```{r, include = FALSE}
#Separamos el texto en los diferentes elementos, genera una lista
lista <- str_split(tabla,'\n')

#Extraemos la parte de los datos
extraigo <- lista[[1]][8:27]

#Arreglamos el nombre de países bajos
extraigo[14] <- str_replace(extraigo[14], 'Países Bajos', 'Países_Bajos')

#Arreglamos el esfuerzo fiscal de España
extraigo[5] <- str_replace(extraigo[5], ':', '.')

#Extraemos los componentes de cada línea
separo <- str_split(extraigo, ' ', simplify = T)

#Transformamos a dataframe y nos quedamos con las 5 primeras columnas
df <- as.data.frame(separo) %>% 
  select(pais = V1,
         presion_valor = V2,
         presion_ranking = V3,
         esfuerzo_valor = V4,
         esfuerzo_ranking = V5) %>%
  mutate(presion_valor = as.numeric(presion_valor),
         esfuerzo_valor = as.numeric(esfuerzo_valor))
```

Tras el proceso de extracción con OCR y una primera limpieza de datos hemos obtenido la siguiente tabla:

```{r, echo = FALSE}
df
```

Vemos que en los rankings hay datos que el ocr no ha podido extraerlos bien.

Pero los valores sí parecen estar todos bien.

Así que vamos a generar de nuevo los rankings a partir de los valores.

Nos fijamos en que el valor 1 se le da al valor más alto en ambos casos.

```{r, echo = FALSE}
df <- df %>% 
  mutate(presion_ranking = row_number(desc(presion_valor)),
         esfuerzo_ranking = row_number(desc(esfuerzo_valor)))

df
```

\pagebreak
Ahora ya pasamos a la fase de visualización.

Analizamos primero como está España en cuanto a presión fiscal (impuestos recaudados / PIB)

```{r, echo = FALSE}
ggplot(df, aes(pais, presion_valor)) +
  geom_linerange(
    aes(x = reorder(pais, -presion_valor),
      ymin = 0,
      ymax = presion_valor),
    color = 'red',
    alpha = 0.3,
    size = 4) +
  geom_point(size = 10, color = 'red') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, size = 10))
```

\pagebreak
Pero ahora vemos el esfuerzo fiscal (ajuste por renta per capita)

```{r, echo = FALSE}
ggplot(df, aes(pais, esfuerzo_valor)) +
  geom_linerange(
    aes(x = reorder(pais, -esfuerzo_valor),
      ymin = 0,
      ymax = esfuerzo_valor),
    color = 'red',
    alpha = 0.3,
    size = 4) +
  geom_point(size = 10, color = 'red') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, size = 10))
```

\pagebreak
Y ahora vamos a crear un mapa de posicionamiento con los 2 indicadores a la vez

```{r, echo = FALSE}
ggplot(df, aes(x = presion_ranking, y = esfuerzo_ranking)) +
  geom_label(aes(label = pais)) +
  theme_bw()
```

\pagebreak
# 3. ANALISIS DE LAS PARTIDAS DEL GASTO

Parece que aunque a nivel del indicador de presión fiscal España todavía tendría recorrido para subir impuestos, cuando analizamos el esfuerzo real que los impuestos actuales ya suponen para el contribuyente solo hay 3 países por encima de España.

En muchos casos se justifica ese esfuerzo alegando que es necesario para mantener servicios como la sanidad, la educación o la protección social.

Vamos a visualizar cómo se distribuyen las partidas del gasto público según datos del Ministerio de Hacienda obtenidos de:

https://www.epdata.es/datos/gasto-publico-espana-datos-graficos/256

Gráfico: Gasto público en España por partida de gasto

```{r, include = FALSE}
gasto <- read_csv2('gasto_publico_en_españa_p.csv') %>% 
  clean_names() 

View(gasto)
```

```{r, include = FALSE}
#Nos vamos a quedar solo con 2018, que es la fila 7
#Y hacemos varias operaciones para conseguir los datos que queremos
gasto <- gasto %>% 
  slice(7) %>% 
  select(-periodo) %>% 
  pivot_longer(-ano,names_to = 'partida', values_to = 'gasto') %>% 
  mutate(total = sum(gasto),
         porc = gasto / total * 100) %>% 
  arrange(desc(porc)) %>% 
  mutate(porc_acum = cumsum(porc))

gasto
```

A partir de la fuente citada y limpiando y organizando los datos obtenemos la siguiente tabla:

```{r, echo = FALSE}
gasto
```

\pagebreak
Que podemos ver de forma gráfica

```{r, echo = FALSE}
ggplot(gasto,aes(x = reorder(partida, porc), y = porc)) + 
  geom_col() + 
  geom_text(aes(label = round(porc,digits = 2)), size = 3, color = 'black', hjust = -1) +
  ylim(0, 50) +
  coord_flip() +
  theme_bw()
```


# 4. CONCLUSIONES

```{r, include = FALSE}
#Calculamos los datos necesarios
ranking_presion <- df %>% slice(5) %>% pull(presion_ranking)
ranking_esfuerzo <- df %>% slice(5) %>% pull(esfuerzo_ranking)
gasto_social <- gasto %>% slice(1) %>% pull(porc)
gasto_sanidad <- gasto %>% slice(2) %>% pull(porc)
gasto_educacion <- gasto %>% slice(5) %>% pull(porc)

sanidad_educacion <- round(gasto_sanidad + gasto_educacion,2)
sanidad_educacion_social <- round(gasto_sanidad + gasto_educacion + gasto_social,2)
```

* La presión fiscal en España es de las más bajas, ocupando el puesto `r ranking_presion` en un ranking de 20 países

* Sin embargo, el esfuerzo real para los contribuyentes es de los mayores, ocupando el puesto `r ranking_esfuerzo` en un ranking de 20 países

* El gasto de sanidad + educación suma el `r sanidad_educacion` por ciento

* Y si añadimos protección social suma el `r sanidad_educacion_social` por ciento

* QUE CADA UNO SAQUE SUS PROPIAS CONCLUSIONES!!!
