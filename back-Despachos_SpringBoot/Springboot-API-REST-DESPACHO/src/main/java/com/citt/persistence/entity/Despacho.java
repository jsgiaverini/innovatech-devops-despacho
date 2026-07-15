package com.citt.persistence.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Despacho {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long idDespacho;

    @NotNull(message = "La fecha de despacho es obligatoria")
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    private LocalDate fechaDespacho;

    @NotBlank(message = "La patente del camión es obligatoria")
    private String patenteCamion;

    @PositiveOrZero(message = "Los intentos no pueden ser negativos")
    private Integer intento;

    @NotNull(message = "El ID de compra es obligatorio")
    private Long idCompra;

    @NotBlank(message = "La dirección de compra es obligatoria")
    private String direccionCompra;

    @NotNull(message = "El valor de compra es obligatorio")
    @PositiveOrZero(message = "El valor de compra no puede ser negativo")
    private Long valorCompra;

    private Boolean despachado;
}
