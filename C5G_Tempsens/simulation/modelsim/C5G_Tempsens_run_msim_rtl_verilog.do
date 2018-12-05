transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/saqata/quartus/C5G_Tempsens/C5G_Tempsens {/home/saqata/quartus/C5G_Tempsens/C5G_Tempsens/clock_generator.v}
vlog -vlog01compat -work work +incdir+/home/saqata/quartus/C5G_Tempsens/C5G_Tempsens {/home/saqata/quartus/C5G_Tempsens/C5G_Tempsens/C5G_Tempsens.v}

